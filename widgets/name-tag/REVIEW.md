# Review: Name Tag (Window Title Widget)

*A name badge / a collar tag.* A Plasma 6 panel widget (`Plasma/Applet`, Id `com.github.techonerd.nametag`, version `0.1.0`) that displays the active window's icon and title in the panel, replacing the broken legacy *Window Title* applet.

---

## What was built

- **Public APIs only:** Uses `org.kde.taskmanager` (`TasksModel`, `ActivityInfo`, `VirtualDesktopInfo`). Absolutely no private `org.kde.plasma.private.*` modules or deprecated `org.kde.plasma.core` modules.
- **Active Task Tracking:** Reactive binding to `tasksModel.activeTask`, tracking window title changes (`Qt.DisplayRole`) and window icons (`Qt.DecorationRole`) with zero polling.
- **Empty State Configuration:** When no window is focused, can show:
  1. Current Activity Name (default, with fallback to "Desktop")
  2. Fixed "Desktop" label
  3. Custom user text
  4. Blank (hidden)
- **Configurable Options (KCFG Synchronized):**
  - `show_icon` (bool, default `true`)
  - `show_title` (bool, default `true`)
  - `bold_title` (bool, default `false`)
  - `max_width` (int, default `300` px; `0` for unlimited width)
  - `empty_text_mode` (int, default `0`)
  - `empty_custom_text` (string, default `""`)
  - Fully compliant Plasma 6 configuration page declaring both `cfg_<key>` and `cfg_<key>Default` for every entry in `main.xml`.
- **Panel Support:** Works seamlessly in both horizontal and vertical panels, properly eliding long titles and respecting Kirigami theme colors.
- **Icons:**
  - `contents/icons/name-tag-symbolic.svg` (monochrome collar tag using `.ColorScheme-Text`)
  - `contents/icons/name-tag.svg` (full color collar tag in Tabby & Tweed palette)
- **Real Offscreen Previews:**
  - `preview/panel_dark.png` (Horizontal panel, active window: Kate)
  - `preview/panel_light.png` (Horizontal panel, active window: Dolphin)
  - `preview/panel_empty_dark.png` (Horizontal panel, no active window)
  - `preview/panel_empty_light.png` (Horizontal panel, no active window)
  - `preview/panel_vertical_dark.png` (Vertical panel, dark mode)
  - `preview/panel_vertical_light.png` (Vertical panel, light mode)
  - `preview/config_dark.png` (General configuration settings dialog, dark theme)
  - `preview/config_light.png` (General configuration settings dialog, light theme)
  - `preview/preview.png` (High-resolution 2560x1440 composite showcase)
- **Packaging:** Integrated into `./build.sh` generating `dist/name-tag-0.1.0.plasmoid`.
- **Permissions:** Strict POSIX permission enforcement across package: directories `755`, regular files `644`, scripts `755`.

---

## How it was tested (safe, no install)

1. **Logic & Compliance Test Suite:**
   ```bash
   python3 -I widgets/name-tag/tools/test_logic.py
   ```
   *Result:*
   ```text
   === Name Tag Logic & Compliance Verification ===
   PASS: All 6 KCFG entries verified with matching cfg_<key> and cfg_<key>Default in configGeneral.qml.
   PASS: metadata.json schema and Plasma 6 compliance verified.
   PASS: Fallback title empty state logic verified across all 4 modes.
   PASS: Width bounding and layout calculations verified.
   PASS: Theme compliance verified; 0 hardcoded colors in 2 QML files.
   === All 5 Tests Passed Successfully ===
   ```

2. **QML Linting:**
   ```bash
   /usr/lib/qt6/bin/qmllint -I /usr/lib/x86_64-linux-gnu/qt6/qml widgets/name-tag/contents/ui/*.qml widgets/name-tag/contents/config/*.qml
   ```
   *Result:* Exited with code 0 (only expected unqualified `i18n` warnings).

3. **Offscreen Rendering & Composite Previews:**
   ```bash
   widgets/name-tag/tools/render.sh
   ```
   *Result:* Successfully rendered 8 offscreen preview states and generated `widgets/name-tag/preview/preview.png` (2560x1440).

4. **Package Build Verification:**
   ```bash
   ./build.sh
   ```
   *Result:* Successfully packaged `dist/name-tag-0.1.0.plasmoid` (11 files, 5693 bytes).

5. **Permission Verification:**
   ```bash
   find widgets/name-tag/ -printf "%m %p\n" | sort -k2
   ```
   *Result:* Verified all directories `755`, regular files `644`, scripts `755`.

---

## Owner Try-Out Commands

Run these commands manually if you wish to install and test the widget on your live Plasma 6 session:

### Install
```bash
kpackagetool6 -t Plasma/Applet -i widgets/name-tag
```

### Try it
1. Right-click your panel → **Add Widgets…** (or **Enter Edit Mode**).
2. Search for **Name Tag** and drag it to your panel.
3. (Optional) Remove the old broken window title widget:
   ```bash
   kpackagetool6 -t Plasma/Applet -r org.kde.windowtitle
   ```

### Undo / Remove
```bash
kpackagetool6 -t Plasma/Applet -r com.github.techonerd.nametag
```
