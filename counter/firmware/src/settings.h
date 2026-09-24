// Runtime settings (sheet URL, API key, station identity). Set through the
// on-device setup portal and stored in NVS; config.h supplies defaults.
#pragma once
#include <Arduino.h>

struct Settings {
    String sheetUrl;
    String apiKey;
    String stationId;
    String stationName;
};
extern Settings settings;

void settingsLoad();
void settingsSave();
bool settingsComplete();     // enough to talk to the sheet
