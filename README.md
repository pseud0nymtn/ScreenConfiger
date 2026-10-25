# ScreenConfiger – Screen Switch (KDE Plasma 6 Widget)

A small Plasma widget that looks like a switch and turns a display output (e.g. `DP-2`, `HDMI-A-1`) on or off. It works in a **panel** as well as on the **desktop**.

- **Click** the switch: turn the output on/off
- **Long press**: opens System Settings directly in *Display Configuration* (`kcm_kscreen`)
- The state is refreshed every 5 seconds (e.g. if the output was changed elsewhere).
- The icon on the switch can be changed in the configuration dialog: pick a theme icon with the icon picker or choose your own image (PNG, JPG, SVG, …).
- In desktop edit mode the standard Plasma "Show Background" toggle is available for the widget frame.
- The switch background can be customised with separate on/off colors and an opacity slider (0–100%). Reset either color to follow the Plasma theme.
- Hovering the widget shows a tooltip with the configured output.
- Optionally the monitor name can be shown next to the switch (above, left, right or below) with configurable text size, maximum length (longer names are cut off with "..."), and spacing to the switch.
- The size of the icon inside the switch can be adjusted.
- The configuration dialog shows monitors by manufacturer and model (read from EDID), e.g. `Dell AW2725D (DP-2)`.
- Safety net: the last active output cannot be switched off.

## Structure

| Part | Description |
|------|-------------|
| `src/main.rs` | Rust helper `screenconfiger` (backend). Reads and switches outputs via `kscreen-doctor` and opens `kcmshell6 kcm_kscreen`. |
| `plasmoid/` | Plasma widget (QML UI) that calls the helper. Plasma widgets themselves must be written in QML; the logic lives in Rust. |

Helper commands:

```
screenconfiger list              # connected outputs as JSON
screenconfiger status <output>   # on | off
screenconfiger toggle <output>
screenconfiger on|off <output>
screenconfiger settings          # open Display Configuration
```

## Requirements

- KDE Plasma 6 (including `kscreen-doctor`, `kcmshell6`, `kpackagetool6`)
- Rust (Cargo, edition 2024 → Rust ≥ 1.85)
- Optional: `hwdata` (`/usr/share/hwdata/pnp.ids`) to show full manufacturer names

## Build

```sh
cargo build --release
```

The binary is then located at `target/release/screenconfiger`.

## Install

```sh
./install.sh
```

The script builds the helper, copies it to `~/.local/bin/screenconfiger` and installs the widget for the current user via `kpackagetool6`. Running it again updates the widget. If the widget does not show up in the list, restart Plasma:

```sh
systemctl --user restart plasma-plasmashell.service
```

If you update an already added widget, restart Plasma (command above) so the new QML and settings schema are loaded.

Then: right-click the panel/desktop → *Add Widgets* → **Screen Switch**.

## Configure

Right-click the widget → *Configure Screen Switch…* and select the desired output. As long as none is selected, a click opens the display settings.

## Uninstall

```sh
./uninstall.sh
```

## Notes

- The helper must be located in `~/.local/bin` (or `/usr/local/bin`) so the widget can find it.
- The widget is written for Plasma 6; Plasma 5 would require adjustments.
