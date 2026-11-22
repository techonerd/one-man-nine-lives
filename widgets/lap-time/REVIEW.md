# Review: Lap Time (Break Reminder Widget)

*Your lap time / the cat claiming your lap.* A Plasma 6 panel applet (`Plasma/Applet`, Id `com.github.techonerd.laptime`, version `0.1.0`) that tracks your work time, reminds you to rest your eyes (20-20-20 rule), and invites Casper onto your screen for full stretch breaks.

---

## What Was Built & Fixed

### 1. Palette & Colours (Strict Suite Look & Feel)
- **Soft Black and White (Zero Pure #000 / #FFF):**
  - Dark Theme: background `#141414`, foreground `#E6E6E6`, muted text `#A0A0A0`.
  - Light Theme: background `#F7F7F7`, foreground `#1C1C1C`, muted text `#666666`.
- **Text & Icon Contrast:**
  - Break titles (`eyeLabel`, `stretchLabel`) and popup header explicitly styled with `monoFg` (`#E6E6E6` dark, `#1A1A1A` light).
  - Statistics labels ("Worked", "Taken", "Skipped") explicitly styled with `monoMuted` (`#A0A0A0` dark, `#666666` light), eliminating dark-on-dark contrast issues.
  - Header and button icons use `Kirigami.Icon` with `isMask: true` and `color: monoFg`.
- **Rims & Overlays Matching Doorstep Glass:**
  - 1px soft rim border with 0.12 opacity (`Qt.rgba(1, 1, 1, 0.12)` in dark mode, `Qt.rgba(0, 0, 0, 0.12)` in light mode).
  - Translucent glass overlay matching Doorstep glass (`Qt.rgba(20/255, 20/255, 20/255, 0.70)` in dark mode, `Qt.rgba(247/255, 247/255, 247/255, 0.75)` in light mode).
- **Amber Accent:**
  - `#964C12` in light mode, `#E8A256` in dark mode for highlights, countdown timers, and progress rings.
- **Removed Hardcoded Raw RGB:**
  - Removed raw numeric RGB values (`Qt.rgba(1, 0.7, 0, 0.2)`, `Qt.rgba(0, 0.8, 0.2, 0.2)`) from `main.qml` and pure `#0E0E0E` / `#FFFFFF` from `Overlay.qml`.
  - Semantic system colors implemented via `Kirigami.Theme`: `neutralTextColor`, `positiveTextColor`, `highlightColor`, `disabledTextColor`.

### 2. Glass Effects & Controls
- **Frosted Glass with MultiEffect Blur:**
  - Integrated `QtQuick.Effects` `MultiEffect` (`blurEnabled: true`, `blur: 0.75`) in `Overlay.qml` (both for fullscreen stretch break card and bottom eye break strip) and in `main.qml` (`fullRepresentation` popup dialog).
- **PlasmaComponents3 & Kirigami Controls:**
  - Native PlasmaComponents3 buttons and labels only.
  - Standard system icon names only: `chronometer`, `alarm-symbolic`, `media-skip-forward`, `dialog-ok`, `media-playback-pause`, `appointment-recurring`, `media-playback-start`.
- **Casper SVG Artwork:**
  - All 4 SVG assets (`casper-sleeping-dark.svg`, `casper-sleeping-light.svg`, `casper-sitting-dark.svg`, `casper-sitting-light.svg`) strictly conform to suite guidelines:
    - Coat: off-white `#F5F5F5` (never pure `#FFFFFF`).
    - Light mode: crisp near-black outline (`#1C1C1C`, 3.2px), subtle shadow (`rgba(0, 0, 0, 0.12)`), `#EFEFEF` contrast pad.
    - Dark mode: clean silhouette without outline (`stroke="none"`), soft white sleeping Zzz (`#E6E6E6`), shadow (`rgba(0, 0, 0, 0.45)`).

### 3. Applet Architecture & Ergonomics
- **Package Structure:** Standard Plasma 6 `Plasma/Applet` package in `widgets/lap-time/` with `metadata.json` (Id `com.github.techonerd.laptime`, version `0.1.0`).
- **Configuration (`main.xml`):**
  - `eyeEnabled` (bool, default `true`): Enable 20-20-20 eye break reminders.
  - `eyeIntervalMin` (int, default `20` min): Interval between eye breaks.
  - `eyeLengthSec` (int, default `20` sec): Duration of eye rest.
  - `eyeLabel` (string, default `"Eye break"`): Custom label for eye breaks.
  - `stretchEnabled` (bool, default `true`): Enable full stretch breaks.
  - `stretchIntervalMin` (int, default `50` min): Interval between stretch breaks.
  - `stretchLengthMin` (int, default `5` min): Duration of stretch breaks.
  - `stretchLabel` (string, default `"Stretch break"`): Custom label for stretch breaks.
  - `snoozeMin` (int, default `5` min): Snooze duration.
  - `maxSnoozes` (int, default `3` times): Maximum snoozes allowed per break before enforcement.
  - `respectDnd` (bool, default `true`): Suppress fullscreen overlays when Plasma Do Not Disturb or presentation mode is active.
  - Daily stats keys (`statsDate`, `statsWorkSec`, `statsBreaksTaken`, `statsBreaksSkipped`).
- **Configuration Page (`configGeneral.qml`):** Compliant Plasma 6 `KCM.SimpleKCM` declaring both `cfg_<key>` and `cfg_<key>Default` for every single entry in `main.xml`.
- **Wayland-Safe Idle & Lock Detection:**
  - Uses Plasma5Support `powermanagement` data engine (`UserActivity`, `IdleTime` in ms) to pause work time when idle > 1 min.
  - Automatically marks stretch break taken if user steps away for longer than break duration.
  - D-Bus integration for ScreenSaver and Notification inhibition (Do Not Disturb).
- **Non-Forced Ergonomics:**
  - Snooze up to configured max limit.
  - Skip break button and instant **Esc** keyboard shortcut dismisses overlay immediately.

---

## Verification & Commands

### 1. QML Lint (`qmllint`)
```bash
/usr/lib/qt6/bin/qmllint -I /usr/lib/x86_64-linux-gnu/qt6/qml \
  widgets/lap-time/contents/ui/main.qml \
  widgets/lap-time/contents/ui/configGeneral.qml \
  widgets/lap-time/contents/ui/Overlay.qml \
  widgets/lap-time/contents/config/config.qml
```
**Output:**
```
Exit code: 0
(Clean pass; only expected "unqualified i18n" framework notices).
```

### 2. Logic Verification
```bash
python3 -I widgets/lap-time/tools/test_logic.py
```
**Output:**
```
=== Lap Time Logic Verification ===
PASS: 1 min timer countdown triggers eye break at exact interval.
  Snooze #1: snoozeCount=1, rescheduled by 300s
  Snooze #2: snoozeCount=2, rescheduled by 300s
  Snooze #3: snoozeCount=3, rescheduled by 300s
PASS: Snooze limits to maxSnoozes, and Skip correctly resets countdown.
PASS: Esc shortcut cleanly dismisses the stretch overlay and marks break skipped.
PASS: ScreenSaver.GetActive and Notifications.Inhibited output parsing verified.
PASS: UserActivity.IdleTime correctly pauses work accumulation during user idle.
=== All 4 Logic Tests Passed Successfully ===
```

### 3. File & Directory Permissions Check
```bash
find widgets/lap-time -exec stat -c "%a %F %n" {} +
```
**Result:**
- Directories: strictly `755`
- Regular files: strictly `644`
- Scripts (`test-widget.sh`, `tools/render.sh`, `tools/test_logic.py`, `tools/composite_previews.py`): strictly `755`

### 4. Real QML Offscreen Renders
Generated via `widgets/lap-time/tools/render.sh` (`QT_QPA_PLATFORM=offscreen` test harness):
- [panel_dark.png](file:///home/techonerd/one-man-nine-lives/widgets/lap-time/preview/panel_dark.png) (360x56)
- [panel_light.png](file:///home/techonerd/one-man-nine-lives/widgets/lap-time/preview/panel_light.png) (360x56)
- [popup_dark.png](file:///home/techonerd/one-man-nine-lives/widgets/lap-time/preview/popup_dark.png) (420x500, full contrast on break names and stats)
- [popup_light.png](file:///home/techonerd/one-man-nine-lives/widgets/lap-time/preview/popup_light.png) (420x500)
- [eye_strip_dark.png](file:///home/techonerd/one-man-nine-lives/widgets/lap-time/preview/eye_strip_dark.png) (1920x1080, real 90px frosted bottom strip with walking Casper and countdown)
- [eye_strip_light.png](file:///home/techonerd/one-man-nine-lives/widgets/lap-time/preview/eye_strip_light.png) (1920x1080)
- [stretch_overlay_dark.png](file:///home/techonerd/one-man-nine-lives/widgets/lap-time/preview/stretch_overlay_dark.png) (1920x1080, real fullscreen frosted overlay with sleeping Casper card and controls)
- [stretch_overlay_light.png](file:///home/techonerd/one-man-nine-lives/widgets/lap-time/preview/stretch_overlay_light.png) (1920x1080)
- [preview.png](file:///home/techonerd/one-man-nine-lives/widgets/lap-time/preview/preview.png) (2560x1440 composite preview)

### 5. Build Package Verification
```bash
./build.sh
```
**Output:**
```
total 3476
...
-rw-rw-rw- 1 techonerd techonerd   14619 Nov 22 02:08 lap-time-0.1.0.plasmoid
...
```
Successfully built `dist/lap-time-0.1.0.plasmoid`.

---

## Safe Testing Protocol (Owner Only)

### Live Test in a Standalone Window (Zero System Changes):
Run the isolated test script from the repository root:
```bash
./widgets/lap-time/test-widget.sh
```
*(This opens Lap Time in a native desktop window showing the full popup interface with Eye Break and Stretch Break countdowns, "Take now" buttons, pause controls, and daily statistics. Closing the window cleanly terminates the test and removes the temporary package mapping).*

### Optional: Test via `plasmoidviewer` (if plasma-sdk is installed):
```bash
./widgets/lap-time/test-widget.sh --viewer
```

### Install to Panel (User level, no root needed):
```bash
kpackagetool6 -t Plasma/Applet -i widgets/lap-time
# or to upgrade:
kpackagetool6 -t Plasma/Applet -u widgets/lap-time
```
Then add **Lap Time** from the Plasma widget explorer to your panel.

### Undo / Uninstall:
```bash
kpackagetool6 -t Plasma/Applet -r com.github.techonerd.laptime
```
