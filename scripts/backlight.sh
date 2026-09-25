#!/bin/sh
# Prints brightnessctl machine lines, then blocks on sysfs changes.
# Exits immediately when the machine has no backlight.

if ! brightnessctl -m -c backlight >/dev/null 2>&1; then
    exit 0
fi

brightnessctl -m -c backlight

if ! command -v inotifywait >/dev/null 2>&1; then
    exit 0
fi

set -- /sys/class/backlight/*/actual_brightness
if [ ! -e "$1" ]; then
    exit 0
fi

inotifywait -m -e modify "$@" 2>/dev/null | while read -r _; do
    brightnessctl -m -c backlight
done
