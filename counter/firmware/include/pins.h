// Fixed CYD (ESP32-2432S028R) peripherals. The TFT pins live in
// platformio.ini build_flags because TFT_eSPI reads them at compile time.
#pragma once

// XPT2046 resistive touch controller - its own SPI bus (VSPI pins).
#define XPT2046_IRQ   36
#define XPT2046_MOSI  32
#define XPT2046_MISO  39
#define XPT2046_CLK   25
#define XPT2046_CS    33

// Raw touch extents for rotation 1 (landscape, USB to the right).
// Tweak if taps land off-centre; run with SERIAL_TOUCH_DEBUG to see raw values.
#define TS_MINX 200
#define TS_MAXX 3700
#define TS_MINY 240
#define TS_MAXY 3800

// On-board RGB LED, common anode: LOW = on.
#define PIN_LED_R 4
#define PIN_LED_G 16
#define PIN_LED_B 17

// Other on-board bits (unused, listed so nobody re-uses the pins by accident)
#define PIN_LDR      34   // light sensor, ADC input-only
#define PIN_SPEAKER  26
#define PIN_SD_CS     5   // TF-card slot: 5/18/19/23 are free if no card is fitted
