// WiFi + Google Apps Script uplink, running on core 0 so the UI never
// blocks on a TLS handshake. Events are queued in RAM and mirrored to
// LittleFS, so nothing is lost when the WiFi drops or the power does.
#pragma once
#include <Arduino.h>
#include <vector>

void   uplinkBegin();
void   uplinkEnqueue(const String& eventJson);   // durable, delivered in order
void   uplinkHeartbeat(const String& stateJson); // volatile, latest wins
bool   uplinkOnline();
size_t uplinkPending();
bool   uplinkTimeValid();                        // NTP synced?
uint32_t uplinkEpoch();                          // 0 until synced

// Latest operator / pillow-type lists (from the Config sheet, cached on flash).
void   uplinkGetLists(std::vector<String>& operators, std::vector<String>& types);
