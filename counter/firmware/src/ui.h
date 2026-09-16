// Touch UI for the 320x240 landscape CYD screen.
#pragma once
#include <Arduino.h>
#include <vector>
#include "state.h"

enum Screen { SCR_IDLE, SCR_PICK_OP, SCR_PICK_TYPE, SCR_RUN, SCR_SUMMARY };

enum ButtonId {
    BTN_NONE = 0, BTN_START, BTN_ADD, BTN_SUB, BTN_DEFECT, BTN_FINISH,
    BTN_BACK, BTN_PREV, BTN_NEXT, BTN_OK,
    BTN_ITEM0   // BTN_ITEM0 + i selects picker item i on the current page
};

struct StatusInfo { bool online; size_t pending; const char* clock; };

void uiBegin();
bool uiTouch(int16_t& x, int16_t& y);         // true once per new tap
int  uiHit(int16_t x, int16_t y);             // ButtonId under the tap

void uiDrawIdle(const char* hint);
void uiDrawPicker(const char* title, const std::vector<String>& items, int page,
                  const String& preselect, bool allowBack);
int  uiPickerPages(size_t nItems);
void uiDrawRun(const BatchState& s);
void uiUpdateCount(const BatchState& s);       // just the number + defects
void uiUpdateElapsed(uint32_t seconds);
void uiDrawFinishArmed(bool armed);            // "tap again to finish"
void uiDrawSummary(const BatchState& s, uint32_t seconds);
void uiDrawStatus(const StatusInfo& st);       // header right side
void uiFlash(uint16_t color);                  // brief full-screen border flash
