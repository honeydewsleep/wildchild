#include "state.h"
#include <Preferences.h>

static Preferences prefs;

void stateLoad(BatchState& s) {
    prefs.begin("pbc", true);
    s.running    = prefs.getBool("run", false);
    prefs.getString("bid", s.batchId, sizeof s.batchId);
    prefs.getString("op", s.op, sizeof s.op);
    prefs.getString("type", s.type, sizeof s.type);
    s.count      = prefs.getInt("cnt", 0);
    s.defects    = prefs.getInt("def", 0);
    s.startEpoch = prefs.getUInt("t0", 0);
    s.startUp    = 0;                          // millis restarted with the boot
    s.seq        = prefs.getUInt("seq", 0);
    prefs.getString("lop", s.lastOp, sizeof s.lastOp);
    prefs.getString("ltype", s.lastType, sizeof s.lastType);
    prefs.end();
}

void stateSave(const BatchState& s) {
    prefs.begin("pbc", false);
    prefs.putBool("run", s.running);
    prefs.putString("bid", s.batchId);
    prefs.putString("op", s.op);
    prefs.putString("type", s.type);
    prefs.putInt("cnt", s.count);
    prefs.putInt("def", s.defects);
    prefs.putUInt("t0", s.startEpoch);
    prefs.putUInt("seq", s.seq);
    prefs.putString("lop", s.lastOp);
    prefs.putString("ltype", s.lastType);
    prefs.end();
}
