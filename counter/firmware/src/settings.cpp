#include "settings.h"
#include "config.h"
#include <Preferences.h>

Settings settings;
static Preferences prefs;

void settingsLoad() {
    prefs.begin("cfg", true);
    settings.sheetUrl    = prefs.getString("url", SHEET_URL);
    settings.apiKey      = prefs.getString("key", API_KEY);
    settings.stationId   = prefs.getString("sid", STATION_ID);
    settings.stationName = prefs.getString("sname", STATION_NAME);
    prefs.end();
    if (settings.stationId.isEmpty())   settings.stationId = "blower-1";
    if (settings.stationName.isEmpty()) settings.stationName = settings.stationId;
}

void settingsSave() {
    prefs.begin("cfg", false);
    prefs.putString("url", settings.sheetUrl);
    prefs.putString("key", settings.apiKey);
    prefs.putString("sid", settings.stationId);
    prefs.putString("sname", settings.stationName);
    prefs.end();
}

bool settingsComplete() {
    return settings.sheetUrl.startsWith("https://") && !settings.apiKey.isEmpty();
}
