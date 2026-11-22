# Catnap Lock Screen Review (v0.1.0)

## Overview
Catnap implements a custom Plasma 6 lock screen package (`contents/lockscreen/`) for both `One Man Nine Lives Light` and `One Man Nine Lives Dark` global themes, plus dedicated standalone `Plasma/Shell` packages (`shells/com.github.techonerd.catnap.{dark,light}`):
- **Single Template Generation**: `LockScreenUi.qml` across all packages is generated strictly from ONE source template (`tools/LockScreenUi.qml.in`) by `tools/generate_lockscreen_art.py`. Hand-edited duplicates are eliminated.
- **Controls Color Set**:
  - Uses the normal `Window`/`Button`/`View` colour sets for controls in both modes (`Kirigami.Theme.colorSet: Kirigami.Theme.Window` on root; `Kirigami.Theme.Button` on buttons; `Kirigami.Theme.View` on password field).
  - No `Complementary` colour set in light mode — buttons and text fields follow soft `MONO_LIGHT` (`#F7F7F7` view, `#E8E8E8` button, `#1C1C1C` text).
  - High contrast on button text: Unlock text is clear and readable across both modes.
- **Native Plasma Controls & Public Modules Only**: Built entirely with `org.kde.plasma.components` (PlasmaComponents3: `Button`, `ToolButton`, `Label`), `org.kde.plasma.extras` (`PlasmaExtras.PasswordField`), and `org.kde.kirigami`. Strictly uses public modules only — `org.kde.plasma.private.sessions` and the Switch User button have been completely removed.
- **MultiEffect Frosted Glass**: Uses `QtQuick.Effects` `MultiEffect` (`blurEnabled: true`, `blur: 0.75`) behind semi-transparent panels with `MONO_*.overlay` fill and a 1px `MONO_*.rim` border.
- **Icon Styling in Dark Mode**: Bottom-bar icons (keyboard, virtual keyboard) and warning/error icons explicitly follow the text colour via custom ToolButton delegates with `Kirigami.Icon { isMask: true; color: lockScreenUi.monoFg }` and matching label text, ensuring crisp contrast on dark glass.
- **Casper Mono Palette & Coat Rules**:
  - Casper is **always white** (MONO coat `#F5F5F5`, slightly off-white, never pure `#FFFFFF`).
  - **Light Mode**: Background is `MONO_LIGHT` (`#F7F7F7`). Casper has an outline (`#1C1C1C`), a soft shadow (`rgba(0, 0, 0, 0.12)`), and rests on a mid-tone architectural floor.
  - **Dark Mode**: Background is `MONO_DARK` (`#141414`). Casper has an off-white coat (`#F5F5F5`), no outline, and a faint shadow (`rgba(0, 0, 0, 0.45)`).
- **Sleeping Casper Line Art**: Peaceful sleeping cat line art ("the sixteenth nap of the day") positioned gracefully above the clock during idle, fading slightly when user interaction awakens the unlock dialog.
- **User Avatar File**: Loads the user's profile image file from `kscreenlocker_userIcon` / `kscreenlocker_userImage` with circular clipping. Falls back cleanly to the Casper Mono mascot line art when no image file is present.
- **Password & Authentication**: Uses native `PlasmaExtras.PasswordField` with built-in show/hide eye toggle, shake animation on unlock failure, and full integration with `authenticator`.
- **System Semantic Warnings**: System semantic colours (`Kirigami.Theme.negativeTextColor`, `Kirigami.Theme.neutralTextColor`) combined with official system icons (`dialog-error`, `data-warning`) for failed unlock notices and Caps Lock indication.

---

## Breeze Interface Verification Table

| Feature / Interface Item | Breeze Lock Screen | Catnap Implementation | Status |
|---|---|---|---|
| `root.debug` | Supported | Declared in `LockScreen.qml` | ✅ Matched |
| `root.notification` | Supported | Declared in `LockScreen.qml`, updated on error/info | ✅ Matched |
| `root.viewVisible` | Supported | Declared in `LockScreen.qml` | ✅ Matched |
| `root.clearPassword()` | Signal | Declared in `LockScreen.qml`, clears password field | ✅ Matched |
| `root.notificationRepeated()` | Signal | Declared in `LockScreen.qml` | ✅ Matched |
| `authenticator.onFailed` | Handled | Rejection shake animation + semantic error label | ✅ Matched |
| `authenticator.onSucceeded` | Quits locker | `Qt.quit()` | ✅ Matched |
| `authenticator.startAuthenticating` | Called on UI active | Called when `uiVisible` becomes true | ✅ Matched |
| `authenticator.respond(password)` | Submits password | Called on enter / "Unlock" click | ✅ Matched |
| `authenticator.errorMessage` | Handled | Displayed via `dialog-error` + `negativeTextColor` | ✅ Matched |
| `authenticator.infoMessage` | Handled | Displayed via semantic status label | ✅ Matched |
| `authenticator.onPromptForSecretChanged`| Handled | Automatically focuses `passwordBox` | ✅ Matched |
| `kscreenlocker_userName` | Displayed | Real username or "User" fallback | ✅ Matched |
| `kscreenlocker_userIcon` | Displayed | User avatar file with Casper fallback | ✅ Matched |
| `org.kde.plasma.private.sessions` | Private module in Breeze | **Removed completely** (public modules only) | ✅ Compliant |
| `Switch User` button | Present in Breeze | **Removed completely** (public modules only) | ✅ Compliant |
| `PasswordField` | Eye icon | Native `PlasmaExtras.PasswordField` with built-in eye | ✅ Matched |
| Caps Lock indicator | Warning banner | `data-warning` + `Kirigami.Theme.neutralTextColor` | ✅ Matched |
| Virtual Keyboard | Toggle button | `PlasmaComponents3.ToolButton` (`input-keyboard-virtual`) + text | ✅ Matched |
| Keyboard layout | Layout switcher | `PlasmaComponents3.ToolButton` (`input-keyboard`) + text | ✅ Matched |

---

## Commands & Verification Results

### 1. Generation from Single Template
```bash
$ python3 -I look-and-feel/one-man-nine-lives/tools/generate_lockscreen_art.py
Generated Casper Mono SVGs and LockScreenUi.qml from template for Catnap (light + dark).
```

### 2. QML Lint (`qmllint`)
```bash
$ /usr/lib/qt6/bin/qmllint -I /usr/lib/x86_64-linux-gnu/qt6/qml \
  look-and-feel/one-man-nine-lives/dark/contents/lockscreen/LockScreen.qml \
  look-and-feel/one-man-nine-lives/dark/contents/lockscreen/LockScreenUi.qml \
  look-and-feel/one-man-nine-lives/light/contents/lockscreen/LockScreen.qml \
  look-and-feel/one-man-nine-lives/light/contents/lockscreen/LockScreenUi.qml
```
Result: **Exit code 0** across all files.

### 3. Real QML Offscreen Renders (2560x1600)
All states rendered offscreen to the `preview/` subfolder:
```bash
$ tools/render.sh catnap
Rendering Catnap Lock Screen states (2560x1600)...
Generated Casper Mono SVGs and LockScreenUi.qml from template for Catnap (light + dark).
Successfully rendered: look-and-feel/one-man-nine-lives/preview/catnap_dark.png (2560x1600)
Successfully rendered: look-and-feel/one-man-nine-lives/preview/catnap_error.png (2560x1600)
Successfully rendered: look-and-feel/one-man-nine-lives/preview/catnap_capslock.png (2560x1600)
Successfully rendered: look-and-feel/one-man-nine-lives/preview/catnap_light.png (2560x1600)
Generating composite previews...
Generated composite preview: /home/techonerd/one-man-nine-lives/look-and-feel/one-man-nine-lives/preview/preview-lockscreen.png (3000x1200)
Done rendering previews.
```

Generated renders in `look-and-feel/one-man-nine-lives/preview/`:
- [catnap_dark.png](preview/catnap_dark.png) (2560x1600, dark mode normal)
- [catnap_light.png](preview/catnap_light.png) (2560x1600, light mode normal, true inversion)
- [catnap_error.png](preview/catnap_error.png) (2560x1600, wrong-password error state)
- [catnap_capslock.png](preview/catnap_capslock.png) (2560x1600, Caps Lock active state)
- [preview-lockscreen.png](preview/preview-lockscreen.png) (3000x1200 composite preview)

---

## Safe Testing Protocol (Owner Only)

> [!IMPORTANT]
> Never run `kscreenlocker_greet` directly without an escape hatch.

### Safe Window Test (No System Lock):
```bash
# Test Dark variant:
./look-and-feel/one-man-nine-lives/test-lockscreen.sh

# Test Light variant:
./look-and-feel/one-man-nine-lives/test-lockscreen.sh light
```

### Emergency Escape Hatch (If ever testing full lock):
Before testing any live system lock:
1. Switch to TTY3 (`Ctrl + Alt + F3`) and log in.
2. If the lock screen on TTY1/TTY2 ever misbehaves, return to TTY3 (`Ctrl + Alt + F3`) and run:
   ```bash
   loginctl unlock-session
   ```

### Rollback / Undo:
```bash
./look-and-feel/one-man-nine-lives/uninstall.sh
```
