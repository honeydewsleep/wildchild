// Batch state + NVS persistence. A power cut mid-batch resumes where it
// left off (count, operator, type, batch id) on the next boot.
#pragma once
#include <Arduino.h>

struct BatchState {
    bool     running    = false;
    char     batchId[40] = "";
    char     op[32]     = "";        // operator name
    char     type[32]   = "";        // pillow type
    int32_t  count      = 0;
    int32_t  defects    = 0;
    uint32_t startEpoch = 0;         // unix seconds, 0 if clock unknown at start
    uint32_t startUp    = 0;         // millis() at start (fallback elapsed)
    uint32_t seq        = 0;         // monotonically increasing event number
    char     lastOp[32]   = "";      // pre-selected in the picker next time
    char     lastType[32] = "";
};

void stateLoad(BatchState& s);
void stateSave(const BatchState& s);
