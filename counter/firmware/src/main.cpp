// Pillow Blower Counter - CYD firmware
//
// One device per blower. Workers pick their name + pillow type, then
// count pillows with the big +/- buttons (touch or the panel buttons).
// Every action is logged to a Google Sheet through the Apps Script
// backend (see ../backend), which feeds the wall dashboard.

#include <Arduino.h>
#include <ArduinoJson.h>
#include <time.h>
#include "config.h"
#include "pins.h"
#include "state.h"
#include "uplink.h"
#include "ui.h"
#include "buttons.h"

static BatchState st;
static Screen screen = SCR_IDLE;
static std::vector<String> ops, types;
static int pickPage = 0;
static String pickedOp;
static uint32_t finishArmedAt = 0;      // 0 = not armed
static uint32_t summaryShownAt = 0;
static uint32_t lastStatusMs = 0, lastHbMs = 0, lastElapsedMs = 0, ledOffAt = 0;
static bool switchWasOn = false;

static DebouncedInput btnAdd, btnSub, btnBatch, btnDefect;

// ------------------------------------------------------------------ misc
static void led(bool r, bool g, bool b) {          // common-anode: LOW = on
    digitalWrite(PIN_LED_R, r ? LOW : HIGH);
    digitalWrite(PIN_LED_G, g ? LOW : HIGH);
    digitalWrite(PIN_LED_B, b ? LOW : HIGH);
}
static void blink(bool r, bool g, bool b, uint32_t ms = 80) { led(r, g, b); ledOffAt = millis() + ms; }

static uint32_t elapsedSec() {
    uint32_t now = uplinkEpoch();
    if (st.startEpoch && now > st.startEpoch) return now - st.startEpoch;
    return (millis() - st.startUp) / 1000;
}

static String clockStr() {
    if (!uplinkTimeValid()) return "--:--";
    time_t t = time(nullptr); struct tm tm; localtime_r(&t, &tm);
    char b[8]; strftime(b, sizeof b, "%H:%M", &tm);
    return b;
}

// Build one event record. Fields are what the Apps Script expects.
static String makeEvent(const char* ev, int32_t delta = 0) {
    JsonDocument d;
    d["ev"]      = ev;
    d["seq"]     = ++st.seq;
    d["ts"]      = uplinkEpoch();          // 0 => server estimates from "up"
    d["up"]      = millis();
    d["batch"]   = st.batchId;
    d["op"]      = st.op;
    d["type"]    = st.type;
    d["count"]   = st.count;
    d["defects"] = st.defects;
    if (delta) d["delta"] = delta;
    if (!strcmp(ev, "batch_end")) { d["started"] = st.startEpoch; d["seconds"] = elapsedSec(); }
    String out; serializeJson(d, out);
    return out;
}

static void sendHeartbeat() {
    JsonDocument d;
    d["running"] = st.running;
    d["op"]      = st.op;
    d["type"]    = st.type;
    d["count"]   = st.count;
    d["defects"] = st.defects;
    d["batch"]   = st.batchId;
    d["started"] = st.startEpoch;
    d["seconds"] = st.running ? elapsedSec() : 0;
    d["seq"]     = st.seq;
    String out; serializeJson(d, out);
    uplinkHeartbeat(out);
    lastHbMs = millis();
}

// -------------------------------------------------------------- actions
static void showIdle() {
    screen = SCR_IDLE;
    const char* hint = (BTN_BATCH_LATCHING && btnBatch.fitted() && btnBatch.held())
        ? "Batch switch is ON - tap START to choose operator"
        : "Flip the batch switch or tap START";
    uiDrawIdle(hint);
}

static void showRun() {
    screen = SCR_RUN;
    finishArmedAt = 0;
    uiDrawRun(st);
    uiUpdateElapsed(elapsedSec());
}

static void beginStartFlow() {
    uplinkGetLists(ops, types);
    pickPage = 0;
    screen = SCR_PICK_OP;
    uiDrawPicker("Who is running?", ops, pickPage, st.lastOp, true);
}

static void startBatch(const String& op, const String& type) {
    strlcpy(st.op, op.c_str(), sizeof st.op);
    strlcpy(st.type, type.c_str(), sizeof st.type);
    strlcpy(st.lastOp, st.op, sizeof st.lastOp);
    strlcpy(st.lastType, st.type, sizeof st.lastType);
    st.running = true; st.count = 0; st.defects = 0;
    st.startEpoch = uplinkEpoch(); st.startUp = millis();
    snprintf(st.batchId, sizeof st.batchId, "%s-%lu-%lu", STATION_ID,
             (unsigned long)(st.startEpoch ? st.startEpoch : millis()), (unsigned long)st.seq + 1);
    uplinkEnqueue(makeEvent("batch_start"));
    stateSave(st);
    sendHeartbeat();
    showRun();
}

static void finishBatch() {
    uplinkEnqueue(makeEvent("batch_end"));
    uint32_t sec = elapsedSec();
    st.running = false;
    stateSave(st);
    sendHeartbeat();
    screen = SCR_SUMMARY; summaryShownAt = millis();
    uiDrawSummary(st, sec);
    st.batchId[0] = 0; st.op[0] = 0; st.type[0] = 0;   // keep count/defects for the summary redraw
}

static void addPillow(int32_t delta) {
    if (!st.running) return;
    if (delta < 0 && st.count == 0) return;
    st.count += delta;
    uplinkEnqueue(makeEvent(delta > 0 ? "add" : "sub", delta));
    stateSave(st);
    sendHeartbeat();
    uiUpdateCount(st);
    blink(delta < 0, delta > 0, false);            // green = added, red = removed
}

static void logDefect() {
    if (!st.running) return;
    st.defects++;
    uplinkEnqueue(makeEvent("defect"));
    stateSave(st);
    sendHeartbeat();
    uiUpdateCount(st);
    blink(true, false, false, 200);
}

// Touch or momentary FINISH: first press arms, second press within the
// window finishes. The latching switch finishes directly (it is deliberate).
static void requestFinish(bool direct) {
    if (!st.running) return;
    if (direct || (finishArmedAt && millis() - finishArmedAt < FINISH_CONFIRM_MS)) { finishBatch(); return; }
    finishArmedAt = millis();
    uiDrawFinishArmed(true);
}

// ------------------------------------------------------------- handlers
static void onButton(int id) {
    switch (screen) {
    case SCR_IDLE:
        if (id == BTN_START) beginStartFlow();
        break;
    case SCR_PICK_OP:
    case SCR_PICK_TYPE: {
        const std::vector<String>& items = (screen == SCR_PICK_OP) ? ops : types;
        int pages = uiPickerPages(items.size());
        if (id == BTN_BACK) {
            if (screen == SCR_PICK_TYPE) { screen = SCR_PICK_OP; pickPage = 0;
                uiDrawPicker("Who is running?", ops, pickPage, st.lastOp, true); }
            else showIdle();
        } else if (id == BTN_PREV || id == BTN_NEXT) {
            pickPage = (pickPage + (id == BTN_NEXT ? 1 : pages - 1)) % pages;
            uiDrawPicker(screen == SCR_PICK_OP ? "Who is running?" : "Which pillow?",
                         items, pickPage, screen == SCR_PICK_OP ? st.lastOp : st.lastType, true);
        } else if (id >= BTN_ITEM0) {
            size_t idx = pickPage * 9 + (id - BTN_ITEM0);
            if (idx >= items.size()) break;
            if (screen == SCR_PICK_OP) {
                pickedOp = items[idx];
                screen = SCR_PICK_TYPE; pickPage = 0;
                uiDrawPicker("Which pillow?", types, pickPage, st.lastType, true);
            } else {
                startBatch(pickedOp, items[idx]);
            }
        }
        break;
    }
    case SCR_RUN:
        if (id == BTN_ADD) addPillow(+1);
        else if (id == BTN_SUB) addPillow(-1);
        else if (id == BTN_DEFECT) logDefect();
        else if (id == BTN_FINISH) requestFinish(false);
        break;
    case SCR_SUMMARY:
        if (id == BTN_OK) showIdle();
        break;
    }
}

static void pollPhysical() {
    if (btnAdd.pressed()) {
        if (screen == SCR_RUN) addPillow(+1);
        else if (screen == SCR_SUMMARY) showIdle();
    }
    if (btnSub.pressed() && screen == SCR_RUN) addPillow(-1);
    if (btnDefect.pressed() && screen == SCR_RUN) logDefect();

    if (!btnBatch.fitted()) return;
    if (BTN_BATCH_LATCHING) {
        // Level must be stable (debounced with a long window) before we act.
        bool on = btnBatch.held();
        if (on != switchWasOn) {
            switchWasOn = on;
            if (on && !st.running && screen == SCR_IDLE) beginStartFlow();
            if (on && screen == SCR_SUMMARY && !st.running) beginStartFlow();
            if (!on && st.running) requestFinish(true);
        }
    } else if (btnBatch.pressed()) {
        if (st.running) requestFinish(false);
        else if (screen == SCR_IDLE || screen == SCR_SUMMARY) beginStartFlow();
    }
}

// ------------------------------------------------------------------ main
void setup() {
    Serial.begin(115200);
    delay(100);
    Serial.println("\n[pbc] Pillow Blower Counter " STATION_ID);
    pinMode(PIN_LED_R, OUTPUT); pinMode(PIN_LED_G, OUTPUT); pinMode(PIN_LED_B, OUTPUT);
    led(false, false, true);

    btnAdd.begin(PIN_BTN_ADD);
    btnSub.begin(PIN_BTN_SUB);
    btnDefect.begin(PIN_BTN_DEFECT);
    btnBatch.begin(PIN_BTN_BATCH, BTN_BATCH_LATCHING ? 1500 : 30);

    stateLoad(st);
    st.startUp = millis();
    uplinkBegin();
    uiBegin();

    // Latching switch: trust the switch position over the saved state.
    for (int i = 0; i < 60; i++) { btnBatch.pressed(); delay(30); }
    switchWasOn = btnBatch.fitted() && BTN_BATCH_LATCHING && btnBatch.held();

    if (st.running) {
        Serial.printf("[pbc] resuming batch %s at %ld\n", st.batchId, (long)st.count);
        if (btnBatch.fitted() && BTN_BATCH_LATCHING && !switchWasOn) finishBatch();
        else showRun();
    } else {
        showIdle();
    }
    if (screen == SCR_IDLE && switchWasOn) beginStartFlow();
    sendHeartbeat();
    led(false, false, false);
}

void loop() {
    int16_t x, y;
    if (uiTouch(x, y)) {
        int id = uiHit(x, y);
        if (id != BTN_NONE) onButton(id);
    }
    pollPhysical();

    uint32_t now = millis();
    if (ledOffAt && now > ledOffAt) { ledOffAt = 0; led(false, false, false); }

    if (finishArmedAt && now - finishArmedAt >= FINISH_CONFIRM_MS) {
        finishArmedAt = 0;
        uiDrawFinishArmed(false);
    }
    if (screen == SCR_SUMMARY && now - summaryShownAt > 20000) showIdle();

    if (now - lastStatusMs > 1000) {
        lastStatusMs = now;
        String c = clockStr();
        StatusInfo si{uplinkOnline(), uplinkPending(), c.c_str()};
        uiDrawStatus(si);
        if (!si.online && si.pending) led(true, false, false); else if (!ledOffAt) led(false, false, false);
    }
    if (screen == SCR_RUN && now - lastElapsedMs > 5000) { lastElapsedMs = now; uiUpdateElapsed(elapsedSec()); }
    if (now - lastHbMs > HEARTBEAT_S * 1000UL) sendHeartbeat();
    delay(5);
}
