#!/bin/bash
# Continuous screen auto-rotate for ThinkPad X13 Yoga (21F3S1NK00) using the
# display-side accelerometer's raw sysfs values directly (iio-sensor-proxy's
# dual-sensor fusion flaps unpredictably on this hardware — see memory).

set -u

MONITOR="eDP-1"
TOUCH_DEVICE="wacom-hid-534e-finger"
ACCEL_DIR="/sys/bus/iio/devices/iio:device1"   # HID .11.auto = display accel
POLL_INTERVAL=0.4
DEBOUNCE_READS=3
DEADZONE_RAW=250000   # ~2.45 m/s^2 / ~0.25g, below this magnitude: ignore axis

current_transform=""
pending_transform=""
pending_count=0

read_axis() {
    cat "$ACCEL_DIR/in_accel_$1_raw" 2>/dev/null || echo 0
}

classify() {
    local x y ax ay
    x=$(read_axis x)
    y=$(read_axis y)
    ax=${x#-}
    ay=${y#-}

    if (( ax > ay )); then
        (( ax < DEADZONE_RAW )) && { echo ""; return; }
        if (( x > 0 )); then echo 1; else echo 3; fi   # left-up / right-up
    else
        (( ay < DEADZONE_RAW )) && { echo ""; return; }
        if (( y < 0 )); then echo 0; else echo 2; fi   # normal / upside-down
    fi
}

apply_transform() {
    hyprctl eval "hl.monitor({ output = \"${MONITOR}\", transform = $1 })" >/dev/null 2>&1
    hyprctl eval "hl.device({ name = \"${TOUCH_DEVICE}\", transform = $1 })" >/dev/null 2>&1
}

while true; do
    reading=$(classify)

    if [[ -z "$reading" ]]; then
        pending_count=0
        sleep "$POLL_INTERVAL"
        continue
    fi

    if [[ "$reading" == "$pending_transform" ]]; then
        (( pending_count++ ))
    else
        pending_transform="$reading"
        pending_count=1
    fi

    if (( pending_count >= DEBOUNCE_READS )) && [[ "$pending_transform" != "$current_transform" ]]; then
        apply_transform "$pending_transform"
        current_transform="$pending_transform"
    fi

    sleep "$POLL_INTERVAL"
done
