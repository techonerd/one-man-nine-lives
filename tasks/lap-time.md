# Task: Lap Time (break reminder widget)

Read `AGENTS.md`, `tasks/README.md` and `widgets/lap-time/README.md` (the spec) first. **Low risk:** it's a user-level widget.

## Build
- A Plasma 6 applet in `widgets/lap-time/`: `metadata.json` (Id `com.github.techonerd.laptime`, version 0.1.0), `contents/config/main.xml`, `contents/ui/main.qml`, `contents/ui/configGeneral.qml`, and `contents/ui/Overlay.qml`.
- **Config keys:** `eyeEnabled`, `eyeIntervalMin` (20), `eyeLengthSec` (20), `stretchEnabled`, `stretchIntervalMin` (50), `stretchLengthMin` (5), `snoozeMin` (5), `maxSnoozes` (3), `respectDnd` (true), `eyeLabel`, `stretchLabel`. The config page declares `cfg_<key>` and `cfg_<key>Default` for every key.
- **Idle time:** the Plasma5Support `powermanagement` data engine, source `UserActivity`, key `IdleTime` (milliseconds). It works on Wayland.
  - Do **not** use `org.freedesktop.ScreenSaver.GetSessionIdleTime`: it returns NotSupported on this Wayland session.
- **Lock and Do Not Disturb:** poll every 30 s through the `executable` engine. Both return `true`/`false`, and both were verified on this machine.
  - **Locked:** `qdbus6 org.freedesktop.ScreenSaver /ScreenSaver org.freedesktop.ScreenSaver.GetActive`
  - **Do Not Disturb:** `qdbus6 org.freedesktop.Notifications /org/freedesktop/Notifications org.freedesktop.DBus.Properties.Get org.freedesktop.Notifications Inhibited`
  - **Fallbacks:** if `qdbus6` is missing, try `qdbus`. If both are missing, skip those checks and show a note on the config page.
- **Overlay:** a `QtQuick.Window`.
  - **Eye break:** frameless, stays on top, transparent, click-through (`Qt.WindowTransparentForInput`), a strip at the bottom of the screen.
  - **Stretch break:** `visibility: Window.FullScreen` with blurred glass. Uses PlasmaComponents3 buttons with system icon names: Snooze, Skip, and "I'm on it" (start countdown). Esc skips.
- **Visuals:** Kirigami or MONO colours only, soft black and white, no pure #000/#FFF. Reuse the placeholder Casper SVG from Catnap, with no new art. Animation is a simple walk-in and fade using QML `Behavior` and `NumberAnimation`, and it respects reduced motion (`Kirigami.Units.longDuration == 0` means no animation).
- **Panel:** a compact icon from the system theme (`chronometer`) with a small progress ring to the next break. The popup shows the time until each break, Pause 1 h / Until tomorrow, and today's stats. Stats are stored in the widget config, reset daily.
- **Code:** written from scratch with public APIs only, with no private modules and no credits needed.

## Test (no install)
- Run `qmllint` on every QML file.
- `plasmoidviewer -a widgets/lap-time` (runs from the folder, installs nothing). Set the intervals to 1 min and 10 s, and show that the eye strip and the stretch overlay appear, that snooze and skip work, and that Esc closes the overlay.
- Show the idle and locked parsing with the real `qdbus6` output.
- Take real screenshots of the panel, popup, eye strip and stretch overlay in light and dark, saved in `widgets/lap-time/preview/`.

## Deliver
`REVIEW.md` with the commands and results above, and the owner's install and undo commands:
- install: `kpackagetool6 -t Plasma/Applet -i widgets/lap-time` (`-u` to upgrade)
- undo: `kpackagetool6 -t Plasma/Applet -r com.github.techonerd.laptime`
