#include "ui.h"
#include "pins.h"
#include "config.h"
#include <TFT_eSPI.h>
#include <XPT2046_Touchscreen.h>

static TFT_eSPI tft;
static SPIClass tsSpi(VSPI);
static XPT2046_Touchscreen ts(XPT2046_CS, XPT2046_IRQ);

// ---- palette (RGB565) --------------------------------------------------
#define C_BG      0x0000
#define C_PANEL   0x2124            // dark grey
#define C_TEXT    0xFFFF
#define C_MUTED   0x9CD3
#define C_GREEN   0x0560
#define C_GREEN_L 0x2E8B
#define C_ORANGE  0xFB20
#define C_BLUE    0x2C7C
#define C_RED     0xC800
#define C_YELLOW  0xFEA0

struct Btn { int16_t x, y, w, h; int id; };
static Btn btns[16];
static int nBtns = 0;
static Screen cur = SCR_IDLE;
static String stationName = "Counter";

static const int PICK_COLS = 3, PICK_ROWS = 3, PICK_PER_PAGE = 9;

static void addBtn(int16_t x, int16_t y, int16_t w, int16_t h, int id, uint16_t color,
                   const char* label, int font = 4, uint16_t fg = C_TEXT) {
    tft.fillRoundRect(x, y, w, h, 8, color);
    tft.setTextColor(fg, color);
    tft.setTextDatum(MC_DATUM);
    tft.setTextPadding(0);
    tft.drawString(label, x + w / 2, y + h / 2, font);
    if (nBtns < 16) btns[nBtns++] = {x, y, w, h, id};
}

static void header() {
    tft.fillRect(0, 0, 320, 30, C_PANEL);
    tft.setTextDatum(ML_DATUM);
    tft.setTextColor(C_TEXT, C_PANEL);
    tft.setTextPadding(0);
    tft.drawString(stationName, 8, 15, 4);
}

// ------------------------------------------------------------------ init
void uiBegin(const char* name) {
    stationName = name;
    pinMode(TFT_BL, OUTPUT); digitalWrite(TFT_BL, HIGH);
    tft.init();
    tft.setRotation(1);
    tft.fillScreen(C_BG);
    tsSpi.begin(XPT2046_CLK, XPT2046_MISO, XPT2046_MOSI, XPT2046_CS);
    ts.begin(tsSpi);
    ts.setRotation(1);
}

bool uiTouch(int16_t& x, int16_t& y) {
    static bool wasDown = false;
    static uint32_t lastTap = 0;
    bool down = ts.tirqTouched() && ts.touched();
    if (!down) { wasDown = false; return false; }
    if (wasDown) return false;                  // still holding: one event per tap
    if (millis() - lastTap < 150) return false; // resistive-panel bounce
    TS_Point p = ts.getPoint();
    x = constrain(map(p.x, TS_MINX, TS_MAXX, 1, 320), 0, 319);
    y = constrain(map(p.y, TS_MINY, TS_MAXY, 1, 240), 0, 239);
#ifdef SERIAL_TOUCH_DEBUG
    Serial.printf("[touch] raw %d,%d -> %d,%d\n", p.x, p.y, x, y);
#endif
    wasDown = true; lastTap = millis();
    return true;
}

int uiHit(int16_t x, int16_t y) {
    for (int i = 0; i < nBtns; i++) {
        const Btn& b = btns[i];
        // 6 px of slop around every button - fingers in gloves are wide
        if (x >= b.x - 6 && x < b.x + b.w + 6 && y >= b.y - 6 && y < b.y + b.h + 6) return b.id;
    }
    return BTN_NONE;
}

// ---------------------------------------------------------------- screens
void uiDrawIdle(const char* hint) {
    cur = SCR_IDLE; nBtns = 0;
    tft.fillScreen(C_BG);
    header();
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(C_TEXT, C_BG);
    tft.drawString("No batch running", 160, 70, 4);
    tft.setTextColor(C_MUTED, C_BG);
    tft.drawString(hint, 160, 100, 2);
    addBtn(40, 140, 240, 76, BTN_START, C_GREEN, "START BATCH");
}

int uiPickerPages(size_t n) { return max(1, (int)((n + PICK_PER_PAGE - 1) / PICK_PER_PAGE)); }

void uiDrawPicker(const char* title, const std::vector<String>& items, int page,
                  const String& preselect, bool allowBack) {
    cur = SCR_PICK_OP; nBtns = 0;
    tft.fillScreen(C_BG);
    header();
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(C_TEXT, C_BG);
    tft.drawString(title, 160, 44, 4);
    int pages = uiPickerPages(items.size());
    const int gx = 6, gy = 62, gw = 100, gh = 40, gap = 4;
    for (int i = 0; i < PICK_PER_PAGE; i++) {
        size_t idx = page * PICK_PER_PAGE + i;
        if (idx >= items.size()) break;
        int c = i % PICK_COLS, r = i / PICK_COLS;
        bool sel = items[idx] == preselect;
        // long names drop to the small font so they never overflow the tile
        int font = tft.textWidth(items[idx], 4) > gw - 8 ? 2 : 4;
        addBtn(gx + c * (gw + gap), gy + r * (gh + gap), gw, gh, BTN_ITEM0 + i,
               sel ? C_BLUE : C_PANEL, items[idx].c_str(), font);
    }
    if (allowBack) addBtn(6, 196, 80, 40, BTN_BACK, C_PANEL, "BACK", 2);
    if (pages > 1) {
        char pg[16]; snprintf(pg, sizeof pg, "%d / %d", page + 1, pages);
        tft.setTextColor(C_MUTED, C_BG);
        tft.drawString(pg, 160, 216, 2);
        addBtn(200, 196, 54, 40, BTN_PREV, C_PANEL, "<");
        addBtn(260, 196, 54, 40, BTN_NEXT, C_PANEL, ">");
    }
}

static void drawRunInfo(const BatchState& s) {
    tft.fillRect(0, 30, 320, 28, C_BG);
    tft.setTextDatum(ML_DATUM);
    tft.setTextColor(C_YELLOW, C_BG);
    tft.setTextPadding(0);
    String line = String(s.op) + "  -  " + s.type;
    tft.drawString(line, 8, 44, 2);
}

void uiUpdateElapsed(uint32_t sec) {
    if (cur != SCR_RUN) return;
    char buf[16];
    snprintf(buf, sizeof buf, "%lu:%02lu", (unsigned long)sec / 60, (unsigned long)sec % 60);
    tft.setTextDatum(MR_DATUM);
    tft.setTextColor(C_MUTED, C_BG);
    tft.setTextPadding(60);
    tft.drawString(buf, 312, 44, 2);
    tft.setTextPadding(0);
}

void uiUpdateCount(const BatchState& s) {
    if (cur != SCR_RUN) return;
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(C_TEXT, C_BG);
    tft.setTextPadding(206);
    tft.drawNumber(s.count, 105, 112, s.count < 1000 ? 8 : 6);
    char d[24];
    snprintf(d, sizeof d, "defects: %ld", (long)s.defects);
    tft.setTextColor(s.defects ? C_ORANGE : C_MUTED, C_BG);
    tft.setTextPadding(206);
    tft.drawString(d, 105, 168, 2);
    tft.setTextPadding(0);
}

void uiDrawRun(const BatchState& s) {
    cur = SCR_RUN; nBtns = 0;
    tft.fillScreen(C_BG);
    header();
    drawRunInfo(s);
    tft.drawRoundRect(2, 60, 206, 122, 8, C_PANEL);
    // fonts 6/8 are digits-only, so the +/- glyphs are drawn as bars
    addBtn(214, 60, 102, 66, BTN_ADD, C_GREEN, "");
    tft.fillRect(261, 73, 8, 40, C_TEXT); tft.fillRect(245, 89, 40, 8, C_TEXT);
    addBtn(214, 132, 102, 50, BTN_SUB, C_ORANGE, "");
    tft.fillRect(245, 153, 40, 8, C_TEXT);
    addBtn(4, 190, 92, 46, BTN_DEFECT, C_RED, "DEFECT", 2);
    addBtn(102, 190, 214, 46, BTN_FINISH, C_BLUE, "FINISH BATCH");
    uiUpdateCount(s);
}

void uiDrawFinishArmed(bool armed) {
    if (cur != SCR_RUN) return;
    // redraw only the finish button with the confirm prompt
    tft.fillRoundRect(102, 190, 214, 46, 8, armed ? C_YELLOW : C_BLUE);
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(armed ? C_BG : C_TEXT, armed ? C_YELLOW : C_BLUE);
    tft.setTextPadding(0);
    tft.drawString(armed ? "TAP AGAIN TO FINISH" : "FINISH BATCH", 209, 213, armed ? 2 : 4);
}

void uiDrawSummary(const BatchState& s, uint32_t sec) {
    cur = SCR_SUMMARY; nBtns = 0;
    tft.fillScreen(C_BG);
    header();
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(C_TEXT, C_BG);
    tft.drawString("Batch finished", 160, 48, 4);
    tft.setTextColor(C_GREEN_L, C_BG);
    tft.drawNumber(s.count, 160, 105, 8);
    char buf[64];
    snprintf(buf, sizeof buf, "%s  -  %s", s.op, s.type);
    tft.setTextColor(C_YELLOW, C_BG);
    tft.drawString(buf, 160, 150, 2);
    snprintf(buf, sizeof buf, "%ld defects   %lu min", (long)s.defects, (unsigned long)(sec + 30) / 60);
    tft.setTextColor(C_MUTED, C_BG);
    tft.drawString(buf, 160, 170, 2);
    addBtn(100, 190, 120, 44, BTN_OK, C_PANEL, "OK");
}

void uiDrawStatus(const StatusInfo& st) {
    // right side of the header: clock, then link state
    tft.fillRect(170, 0, 150, 30, C_PANEL);
    tft.setTextDatum(MR_DATUM);
    tft.setTextPadding(0);
    if (!st.online) {
        tft.setTextColor(C_ORANGE, C_PANEL);
        char b[24]; snprintf(b, sizeof b, "OFFLINE %u", (unsigned)st.pending);
        tft.drawString(st.pending ? b : "OFFLINE", 312, 15, 2);
    } else if (st.pending) {
        tft.setTextColor(C_YELLOW, C_PANEL);
        char b[24]; snprintf(b, sizeof b, "sending %u", (unsigned)st.pending);
        tft.drawString(b, 312, 15, 2);
    } else {
        tft.setTextColor(C_MUTED, C_PANEL);
        tft.drawString(st.clock, 312, 15, 2);
        tft.fillCircle(230, 15, 4, C_GREEN_L);
    }
}

void uiFlash(uint16_t color) {
    tft.drawRect(0, 0, 320, 240, color);
    tft.drawRect(1, 1, 318, 238, color);
}

bool uiTouchDown() { return ts.tirqTouched() && ts.touched(); }

void uiDrawBoot() {
    nBtns = 0;
    tft.fillScreen(C_BG);
    header();
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(C_TEXT, C_BG);
    tft.drawString("Pillow Counter", 160, 90, 4);
    tft.setTextColor(C_MUTED, C_BG);
    tft.drawString("starting...", 160, 125, 2);
    tft.drawString("hold the screen or the - button for setup", 160, 200, 2);
}

void uiDrawSetup(const char* ap) {
    nBtns = 0;
    tft.fillScreen(C_BG);
    tft.fillRect(0, 0, 320, 30, C_BLUE);
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(C_TEXT, C_BLUE);
    tft.drawString("SETUP MODE", 160, 15, 4);
    tft.setTextDatum(ML_DATUM);
    tft.setTextColor(C_TEXT, C_BG);
    tft.drawString("1. On a phone, join the WiFi network:", 8, 52, 2);
    tft.setTextColor(C_YELLOW, C_BG);
    tft.drawString(ap, 28, 74, 4);
    tft.setTextColor(C_TEXT, C_BG);
    tft.drawString("2. A setup page opens (or go to", 8, 104, 2);
    tft.setTextColor(C_YELLOW, C_BG);
    tft.drawString("http://192.168.4.1", 28, 124, 2);
    tft.setTextColor(C_TEXT, C_BG);
    tft.drawString("3. Enter your WiFi, the sheet link,", 8, 152, 2);
    tft.drawString("   the API key and this station's name.", 8, 170, 2);
    tft.setTextColor(C_MUTED, C_BG);
    tft.drawString("Closes by itself after 10 minutes.", 8, 210, 2);
}

void uiDrawSetupResult(bool wifiOk, bool sheetOk) {
    nBtns = 0;
    tft.fillScreen(C_BG);
    tft.setTextDatum(MC_DATUM);
    tft.setTextColor(wifiOk ? C_GREEN_L : C_ORANGE, C_BG);
    tft.drawString(wifiOk ? "WiFi connected" : "WiFi not connected", 160, 90, 4);
    tft.setTextColor(sheetOk ? C_GREEN_L : C_ORANGE, C_BG);
    tft.drawString(sheetOk ? "Sheet link saved" : "No sheet link - counting offline", 160, 130, 2);
    tft.setTextColor(C_MUTED, C_BG);
    tft.drawString("hold - at power-on to change settings", 160, 200, 2);
}
