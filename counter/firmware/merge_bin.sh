#!/usr/bin/env bash
# Build both CYD variants and merge each into a single image flashable at
# offset 0x0 with https://espressif.github.io/esptool-js/ (Chrome/Edge).
set -euo pipefail
cd "$(dirname "$0")"
pio run -e cyd -e cyd_st7789
ESPTOOL="$HOME/.platformio/packages/tool-esptoolpy/esptool.py"
BOOT0="$HOME/.platformio/packages/framework-arduinoespressif32/tools/partitions/boot_app0.bin"
mkdir -p dist
for env in cyd cyd_st7789; do
    python3 "$ESPTOOL" --chip esp32 merge_bin -o "dist/pillow-counter-$env.bin" \
        --flash_mode dio --flash_freq 40m --flash_size 4MB \
        0x1000 ".pio/build/$env/bootloader.bin" 0x8000 ".pio/build/$env/partitions.bin" \
        0xe000 "$BOOT0" 0x10000 ".pio/build/$env/firmware.bin"
done
ls -la dist/
