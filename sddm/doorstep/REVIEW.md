# Doorstep Review (v0.1.0)

## Overview
Doorstep has been completely rewritten from scratch to follow the modern Plasma 6 native control architecture and the Casper Mono design specification:
- **Native Plasma Controls Only**: Built entirely with `org.kde.plasma.components` (PlasmaComponents3: `Button`, `ToolButton`, `ComboBox`, `Label`), `org.kde.plasma.extras` (`PlasmaExtras.PasswordField` with built-in show/hide eye), and `org.kde.kirigami`. Every hand-drawn `Rectangle` button, box, and custom indicator has been removed.
- **Controls Color Set**:
  - Uses the normal `Window`/`Button`/`View` colour sets for controls in both modes (`Kirigami.Theme.colorSet: Kirigami.Theme.Window` on root; `Kirigami.Theme.Button` on buttons and combo boxes; `Kirigami.Theme.View` on text fields).
  - No `Complementary` colour set in light mode — buttons and text fields follow soft `MONO_LIGHT` (`#F7F7F7` view, `#E8E8E8` button, `#1C1C1C` text).
  - High contrast on button text: Log In / Unlock text is clear and readable across both modes.
- **MultiEffect Frosted Glass**: Uses `QtQuick.Effects` `MultiEffect` (`blurEnabled: true`, `blur: 0.75`) behind semi-transparent panels with `MONO_*.overlay` fill and a 1px `MONO_*.rim` border.
- **Icon Styling in Dark Mode**: Bottom-bar icons (sleep, restart, shut down, virtual keyboard) and warning/error icons explicitly follow the text colour via `icon.color: root.monoFg` on `ToolButton` and `isMask: true` on `Kirigami.Icon`.
- **Casper Mono Palette & Coat Rules**:
  - Casper is **always white** (MONO coat `#F5F5F5`, slightly off-white, never pure `#FFFFFF`).
  - **Light Mode**: Background is `MONO_LIGHT` (`#F7F7F7`). Casper has an outline (`#1C1C1C`), a soft shadow (`rgba(0, 0, 0, 0.12)`), and rests on a mid-tone architectural floor (`#D8D8D8` to `#CECECE`). The doorway line art is clean with no stray dots.
  - **Dark Mode**: Background is `MONO_DARK` (`#141414`). Casper has an off-white coat (`#F5F5F5`), no outline, a faint shadow (`rgba(0, 0, 0, 0.45)`), and sits on a dark plank floor (`#161616`).
  - Live mode switcher in top bar using `PlasmaComponents3.ToolButton` (`weather-clear-night` / `weather-clear`).
- **User Profile Picture**: Automatically loads the user's avatar from their system profile image file (`currentUserItem.icon`). If no picture file exists, falls back cleanly to the Casper Mono mascot emblem.
- **Power Controls**: `PlasmaComponents3.ToolButton` with official system icons: Sleep (`system-suspend`), Restart (`system-reboot`), and Shut Down (`system-shutdown`). Hibernate has been completely removed.
- **Semantic Warnings**: System semantic colours (`Kirigami.Theme.negativeTextColor`, `Kirigami.Theme.neutralTextColor`) combined with system icons (`dialog-error`, `data-warning`) for login failures and Caps Lock indication.

---

## Breeze SDDM Interface Items Matched

| Breeze Item / Concept | Breeze SDDM (`/usr/share/sddm/themes/breeze/`) | Doorstep SDDM Implementation | Status |
|---|---|---|---|
| `sddm` context object | Calls `sddm.login()`, `sddm.suspend()`, `sddm.reboot()`, `sddm.powerOff()` | Calls identical methods via native `PlasmaComponents3` handlers | ✅ Matched |
| `sddm.onLoginFailed` | Connection resets focus & triggers rejection animation | Triggers rejection shake animation & displays semantic error banner | ✅ Matched |
| `sddm.onLoginSucceeded` | Clears error state | Clears error state | ✅ Matched |
| `sddm.onInformationMessage` | Displays greeter message | Displays greeter message in semantic label | ✅ Matched |
| `userModel` | Provides account list, `realName`, `name`, `icon`, `vtNumber` | Full model binding; switches to text field if single or hidden user | ✅ Matched |
| `currentUserItem.icon` | Avatar path from AccountsService | Displays profile image file via `Image` with Casper fallback | ✅ Matched |
| `sessionModel` | Desktop session list (`lastIndex`, `name`) | Bound to native `PlasmaComponents3.ComboBox` | ✅ Matched |
| `keyboard` | Keyboard layout model & current index | Bound to native `PlasmaComponents3.ComboBox` | ✅ Matched |
| `config` | `clockFormat`, `dateFormat`, `background` | Reads SDDM config keys with safe fallbacks | ✅ Matched |
| `PasswordField` | Eye icon for show/hide password | Native `PlasmaExtras.PasswordField` with built-in eye action | ✅ Matched |
| Caps Lock indicator | Warning icon and label | `data-warning` + `Kirigami.Theme.neutralTextColor` | ✅ Matched |
| System power buttons | Suspend, Reboot, PowerOff | `PlasmaComponents3.ToolButton` with `icon.name` + text (Hibernate removed) | ✅ Matched |
| Virtual Keyboard | Toggle button + loader | `PlasmaComponents3.ToolButton` (`input-keyboard-virtual`) + text | ✅ Matched |

---

## Commands & Verification Results

### 1. QML Lint (`qmllint`)
```bash
$ /usr/lib/qt6/bin/qmllint -I /usr/lib/x86_64-linux-gnu/qt6/qml sddm/doorstep/doorstep/Main.qml
```
Result: **Exit code 0** (no syntax or type errors; only expected SDDM runtime context properties flagged as unqualified).

### 2. Real QML Offscreen Renders (2560x1600)
All states rendered offscreen to the `preview/` subfolder:
```bash
$ tools/render.sh doorstep
Rendering Doorstep SDDM states (2560x1600)...
Generated Casper Mono Doorstep SVG assets and parts successfully.
Successfully rendered: sddm/doorstep/preview/doorstep_dark.png (2560x1600)
Successfully rendered: sddm/doorstep/preview/doorstep_error.png (2560x1600)
Successfully rendered: sddm/doorstep/preview/doorstep_capslock.png (2560x1600)
Rendering Doorstep easter egg grab states...
Successfully rendered: sddm/doorstep/preview/grab_waiting.png (2560x1600)
Successfully rendered: sddm/doorstep/preview/grab_watching.png (2560x1600)
Successfully rendered: sddm/doorstep/preview/grab_reaching.png (2560x1600)
Successfully rendered: sddm/doorstep/preview/grab_grabbed.png (2560x1600)
Successfully rendered: sddm/doorstep/preview/grab_released.png (2560x1600)
Successfully rendered: sddm/doorstep/preview/doorstep_light.png (2560x1600)
Generated composite preview: sddm/doorstep/preview/preview.png (3000x1200)
```

---

## Casper Grabs the Cursor Easter Egg

The sitting cat in the bottom-right corner is implemented in `CasperGrabber.qml`:
- **States**: `waiting` → `watching` → `reaching` → `grabbed` → `released`.
  - **Outer Zone**: Hover-only `MouseArea` (`acceptedButtons: Qt.NoButton`, `preventStealing: false`, never steals focus or clicks). Head and eyes turn toward cursor (`Math.atan2`, clamped to ±75°). Eyes stay open (`eyes-open.svg`).
  - **Inner Zone**: Arm rotates toward cursor. After 2s in reaching, the arm extends further (`scale: 1.35` with `Kirigami.Units.longDuration` easing).
  - **Grab Zone**: When cursor touches paw tip, state transitions to `grabbed` for 2 seconds. The zone sets `cursorShape: Qt.BlankCursor` and displays `paw-holding-cursor.svg`. After 2 seconds, state transitions to `released` (`paw-open.svg`, cursor restored).
  - **Tail Swish**: Idle tail swish cycles frames `tail-0.svg` .. `tail-5.svg` slowly (220ms per frame) during `waiting`. Swishing stops while `grabbed`.
  - **Accessibility & Focus**: Decorative only (`Accessible.ignored: true`). Never takes focus or steals clicks from login fields.
  - **Animation Control**: Uses `Behavior`/`NumberAnimation` with `Kirigami.Units.shortDuration` / `longDuration`, automatically disabled when user disables animations.
  - **Config Toggle**: `theme.conf` property `playfulCat=true` (setting to `false` disables interaction and shows the static cat).
- **Art Contract & Modular Parts**:
  - Art specification defined in `art/casper-parts/README.md`.
  - QML loads parts strictly from `casper/<variant>/` (`body.svg`, `head.svg`, `eyes-open.svg`, `eyes-closed.svg`, `arm.svg`, `paw-open.svg`, `paw-closed.svg`, `paw-holding-cursor.svg`, `tail-0..5.svg`).
  - Allows final Illustrator art to drop directly into `casper/{dark,light}/` with zero code modifications.
Generating composite previews...
Generated composite preview: /home/techonerd/one-man-nine-lives/sddm/doorstep/preview/preview.png (3000x1200)
Done rendering previews.
```

Generated renders in `sddm/doorstep/preview/`:
- [doorstep_dark.png](preview/doorstep_dark.png) (2560x1600, dark mode normal)
- [doorstep_light.png](preview/doorstep_light.png) (2560x1600, light mode normal, true inversion)
- [doorstep_error.png](preview/doorstep_error.png) (2560x1600, wrong-password error state)
- [doorstep_capslock.png](preview/doorstep_capslock.png) (2560x1600, Caps Lock active state)
- [preview.png](preview/preview.png) (3000x1200 composite preview)

---

## Safe Testing Protocol (Owner Only)

Preview the theme in a test window without root or altering system files:
```bash
sddm-greeter-qt6 --test-mode --theme ./sddm/doorstep/doorstep
```
*(Click the sun/moon button in the top right to switch between Dark and Light Casper Mono modes live).*

### Install (For later, owner with sudo):
```bash
sudo cp -r sddm/doorstep/doorstep /usr/share/sddm/themes/
sudo mkdir -p /etc/sddm.conf.d
echo -e "[Theme]\nCurrent=doorstep" | sudo tee /etc/sddm.conf.d/20-theme.conf
```

### Rollback / Revert:
```bash
sudo rm -f /etc/sddm.conf.d/20-theme.conf
sudo rm -rf /usr/share/sddm/themes/doorstep
```
*(Your existing `/etc/sddm.conf.d/10-wayland.conf` remains untouched).*
