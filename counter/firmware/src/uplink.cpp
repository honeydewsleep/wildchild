#include "uplink.h"
#include "config.h"
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <LittleFS.h>
#include <ArduinoJson.h>
#include <deque>
#include <time.h>

static const char* QUEUE_FILE  = "/queue.jsonl";
static const char* CONFIG_FILE = "/config.json";
static const size_t QUEUE_MAX  = 3000;   // ~1 shift of clicks with no WiFi
static const int    POST_BATCH = 25;     // events per HTTP request when catching up

static SemaphoreHandle_t mtx;
static std::deque<String> queue;
static String heartbeat;                 // pending heartbeat, "" = none
static volatile bool online = false;
static volatile bool timeOk = false;
static std::vector<String> gOps, gTypes;

// ---------------------------------------------------------------- helpers
static void lock()   { xSemaphoreTake(mtx, portMAX_DELAY); }
static void unlock() { xSemaphoreGive(mtx); }

static void persistQueue() {              // caller holds the lock
    File f = LittleFS.open(QUEUE_FILE, "w");
    if (!f) return;
    for (auto& e : queue) { f.print(e); f.print('\n'); }
    f.close();
}

static void loadQueue() {
    File f = LittleFS.open(QUEUE_FILE, "r");
    if (!f) return;
    while (f.available()) {
        String line = f.readStringUntil('\n');
        line.trim();
        if (line.length() > 2) queue.push_back(line);
    }
    f.close();
    Serial.printf("[uplink] %u queued events restored\n", (unsigned)queue.size());
}

static void applyConfigJson(const String& body, bool save) {
    JsonDocument doc;
    if (deserializeJson(doc, body) || !doc["ok"].as<bool>()) return;
    std::vector<String> ops, types;
    for (JsonVariant v : doc["operators"].as<JsonArray>()) ops.push_back(v.as<String>());
    for (JsonVariant v : doc["types"].as<JsonArray>())     types.push_back(v.as<String>());
    if (ops.empty() || types.empty()) return;
    lock();
    gOps = ops; gTypes = types;
    unlock();
    if (save) {
        File f = LittleFS.open(CONFIG_FILE, "w");
        if (f) { f.print(body); f.close(); }
    }
    Serial.printf("[uplink] config: %u operators, %u types\n", (unsigned)ops.size(), (unsigned)types.size());
}

static void loadCachedConfig() {
    File f = LittleFS.open(CONFIG_FILE, "r");
    if (f) { applyConfigJson(f.readString(), false); f.close(); }
    lock();
    if (gOps.empty())   gOps   = {"Operator 1", "Operator 2", "Operator 3"};
    if (gTypes.empty()) gTypes = {"Standard", "King", "Body"};
    unlock();
}

// --------------------------------------------------------------- network
static bool httpRequest(const char* method, const String& url, const String& body, String& resp) {
    WiFiClientSecure client;
    client.setInsecure();   // Google's cert chain rotates; pinning is opt-in (see README)
    HTTPClient http;
    http.setTimeout(15000);
    http.setFollowRedirects(HTTPC_STRICT_FOLLOW_REDIRECTS);  // Apps Script 302s to googleusercontent
    if (!http.begin(client, url)) return false;
    int code;
    if (body.length()) {
        http.addHeader("Content-Type", "application/json");
        code = http.sendRequest(method, (uint8_t*)body.c_str(), body.length());
    } else {
        code = http.sendRequest(method);
    }
    bool ok = (code == 200);
    if (ok) resp = http.getString();
    else Serial.printf("[uplink] HTTP %s -> %d\n", method, code);
    http.end();
    return ok;
}

static bool fetchConfig() {
    String url = String(SHEET_URL) + "?action=config&key=" + API_KEY + "&station=" + STATION_ID;
    String resp;
    if (!httpRequest("GET", url, "", resp)) return false;
    applyConfigJson(resp, true);
    return true;
}

// Sends up to POST_BATCH queued events (plus a heartbeat if one is pending).
// Returns true when everything sent was acknowledged.
static bool flushOnce() {
    lock();
    size_t n = min(queue.size(), (size_t)POST_BATCH);
    String hb = heartbeat;
    if (n == 0 && hb.isEmpty()) { unlock(); return true; }
    String body = "{\"key\":\"" API_KEY "\",\"station\":\"" STATION_ID "\",\"name\":\"" STATION_NAME "\",\"up\":";
    body += millis();
    body += ",\"events\":[";
    for (size_t i = 0; i < n; i++) { if (i) body += ','; body += queue[i]; }
    body += "]";
    if (!hb.isEmpty()) { body += ",\"live\":"; body += hb; }
    body += "}";
    unlock();

    String resp;
    if (!httpRequest("POST", SHEET_URL, body, resp)) return false;
    JsonDocument doc;
    if (deserializeJson(doc, resp) || !doc["ok"].as<bool>()) {
        Serial.printf("[uplink] server rejected: %s\n", resp.c_str());
        return false;
    }
    lock();
    for (size_t i = 0; i < n && !queue.empty(); i++) queue.pop_front();
    if (heartbeat == hb) heartbeat = "";
    if (n) persistQueue();
    unlock();
    if (n) Serial.printf("[uplink] sent %u events, %u left\n", (unsigned)n, (unsigned)uplinkPending());
    return true;
}

static void uplinkTask(void*) {
    WiFi.mode(WIFI_STA);
    WiFi.setSleep(false);
    WiFi.begin(WIFI_SSID, WIFI_PASS);
    configTzTime(TZ_INFO, "pool.ntp.org", "time.google.com");

    uint32_t lastCfg = 0, backoff = 1000, nextTry = 0;
    for (;;) {
        if (WiFi.status() != WL_CONNECTED) {
            if (online) Serial.println("[uplink] WiFi lost");
            online = false;
            static uint32_t lastReconnect = 0;
            if (millis() - lastReconnect > 10000) { WiFi.reconnect(); lastReconnect = millis(); }
            vTaskDelay(pdMS_TO_TICKS(500));
            continue;
        }
        if (!online) { online = true; Serial.printf("[uplink] WiFi up: %s\n", WiFi.localIP().toString().c_str()); }

        time_t now = time(nullptr);
        timeOk = now > 1700000000;

        if (millis() >= nextTry) {
            bool ok = flushOnce();
            backoff = ok ? 1000 : min(backoff * 2, (uint32_t)60000);
            nextTry = millis() + (ok ? 0 : backoff);
            if (ok && (lastCfg == 0 || millis() - lastCfg > CONFIG_REFRESH_S * 1000UL)) {
                if (fetchConfig()) lastCfg = millis();
                else lastCfg = millis() - CONFIG_REFRESH_S * 1000UL + 60000;  // retry in a minute
            }
        }
        vTaskDelay(pdMS_TO_TICKS(250));
    }
}

// ----------------------------------------------------------------- API
void uplinkBegin() {
    mtx = xSemaphoreCreateMutex();
    if (!LittleFS.begin(true)) Serial.println("[uplink] LittleFS mount failed");
    loadQueue();
    loadCachedConfig();
    xTaskCreatePinnedToCore(uplinkTask, "uplink", 16384, nullptr, 1, nullptr, 0);
}

void uplinkEnqueue(const String& e) {
    lock();
    if (queue.size() >= QUEUE_MAX) queue.pop_front();
    queue.push_back(e);
    persistQueue();
    unlock();
}

void uplinkHeartbeat(const String& s) { lock(); heartbeat = s; unlock(); }
bool   uplinkOnline()    { return online; }
bool   uplinkTimeValid() { return timeOk; }
uint32_t uplinkEpoch()   { return timeOk ? (uint32_t)time(nullptr) : 0; }
size_t uplinkPending()   { lock(); size_t n = queue.size(); unlock(); return n; }
void uplinkGetLists(std::vector<String>& o, std::vector<String>& t) { lock(); o = gOps; t = gTypes; unlock(); }
