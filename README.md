# omarchy-autorotate

Continuous screen auto-rotate for a convertible laptop running Hyprland
(tested on a Lenovo ThinkPad X13 Yoga Gen 4, `21F3S1NK00`, on Omarchy).

Polls the display-side accelerometer's raw sysfs values directly instead of
relying on `iio-sensor-proxy`'s dual-sensor orientation fusion, which flaps
unpredictably on hardware without an `ACCEL_MOUNT_MATRIX` hwdb entry. Rotates
both the output and the touchscreen input device together via Hyprland's
`hyprctl eval` Lua API (`hl.monitor()` / `hl.device()`), since `hyprctl
keyword` is unavailable on Hyprland builds using the newer Lua config engine.

## Setup

Edit the constants at the top of `bin/omarchy-autorotate.sh`:

- `MONITOR` — output name from `hyprctl monitors`
- `TOUCH_DEVICE` — touch device name from `hyprctl devices`
- `ACCEL_DIR` — the *display-side* (not base/keyboard-side) `accel_3d` IIO
  device under `/sys/bus/iio/devices/`; on dual-sensor convertibles this is
  usually the one whose HID sub-address ends `.11.auto` (`.12.auto` is
  typically the base)

Then run it, or add to your Hyprland autostart (e.g. `autostart.lua`):

```lua
o.launch_on_start("~/.local/bin/omarchy-autorotate.sh")
```

## Notes

- Orientation → transform mapping (`classify()`) is calibrated against this
  device's sensor axis orientation; if left/right land backwards on your
  hardware, swap the `1`/`3` branch.
- `DEADZONE_RAW` and `DEBOUNCE_READS` tune sensitivity vs. flappiness.
