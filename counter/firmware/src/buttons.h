// Debounced active-low inputs for the panel buttons.
#pragma once
#include <Arduino.h>

class DebouncedInput {
public:
    // pin -1 = not fitted. pullup=false for input-only pins (34..39) that
    // need an external resistor.
    void begin(int pin, uint32_t debounceMs = 30) {
        _pin = pin; _db = debounceMs;
        if (_pin < 0) return;
        pinMode(_pin, (_pin >= 34) ? INPUT : INPUT_PULLUP);
        _stable = _raw = (digitalRead(_pin) == LOW);
        _t = millis();
    }
    // Call every loop. Returns true once per new press (HIGH->LOW edge).
    bool pressed() {
        if (_pin < 0) return false;
        bool now = (digitalRead(_pin) == LOW);
        if (now != _raw) { _raw = now; _t = millis(); }
        if (now != _stable && millis() - _t >= _db) {
            _stable = now;
            if (_stable) return true;
        }
        return false;
    }
    bool held() const { return _pin >= 0 && _stable; }   // debounced level
    bool fitted() const { return _pin >= 0; }
private:
    int _pin = -1; uint32_t _db = 30, _t = 0; bool _raw = false, _stable = false;
};
