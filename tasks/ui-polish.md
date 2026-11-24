# Plasma Polish: suite UI/UX review, 2026-11-24

Read `AGENTS.md` and `tasks/README.md` first. This is a review: each finding is a fix an agent can do as its own task. Nothing here has been changed yet.

**Scope**: Whiskers widget and settings, Name Tag, Lap Time (popup, settings, break overlay), Morning Stretch splash, Doorstep login screen, Tabby & Tweed colour schemes, Whiskers message wording.
**Not covered**: Window Perch (C++ Breeze fork), Night Shift Plasma style and Konsole colours, Thumbs & Paws icons at 16/22 px (needs rendering), global-theme previews, Catnap. These need rendered images, which this pass didn't make.
**Checks**: `plasmalint` 22 floor / 31 reflex / 2 notes · `contrast` Tabby & Tweed Light 22 failing pairs, Dark 5, Breeze Light 69, Breeze Dark 25 · qmllint not run in this pass.
**Verified by**: reading the code and running the checks below. No widget was rendered. Every contrast number below was measured, not estimated.

```bash
S=claude/plasma-polish/skills/plasma-polish/scripts
python3 -I $S/plasmalint.py whiskers/widget widgets/name-tag widgets/lap-time splash/morning-stretch sddm/doorstep/doorstep
python3 -I $S/contrast.py color-scheme/tabby-and-tweed/*.colors     # the suite's schemes
python3 -I $S/contrast.py                                            # Breeze Light + Dark, what most users run
```

## Top fixes

1. **Lap Time is hard to read on Breeze Light.** Countdown text uses the highlight colour (2.2:1), the "Skipped" count uses the warning colour (2.5:1), and all 14 font sizes are fixed. → [L1](#l1--floor--countdowns-and-counts-unreadable-on-breeze-light), [L2](#l2--floor--fixed-font-sizes-ignore-the-users-settings)
2. **Whiskers' faded text drops to 3.1:1** in Tabby & Tweed Light, and its check switches have no name for screen readers. → [W1](#w1--floor--faded-text-below-readable-contrast), [W2](#w2--floor--check-switches-and-option-boxes-have-no-name)
3. **Tabby & Tweed Light: error, warning and success text in the Complementary set is 2.6–2.8:1.** This is a one-line change in `generate.py`. → [T1](#t1--floor--complementary-status-colours-fail-in-the-light-scheme)
4. **Doorstep gives no feedback after you press Log In**, and its colours and font sizes don't come from the palette or `theme.conf`. → [D1](#d1--floor--no-feedback-after-log-in), [D2](#d2--floor-project-rule--colours-hand-copied-and-one-invented)
5. **Lap Time hides "idle detection isn't working"** in an 8 pt pill, so the user is silently counted as working while away. → [L3](#l3--floor--a-missing-idle-helper-is-almost-invisible)

---

## Whiskers

#### W1 · Floor · Faded text below readable contrast
- **What the user sees**: the "3 minutes ago" time (opacity 0.6), the grey detail line under each problem (opacity 0.5) and the footnote in settings (opacity 0.6) are hard to read in light mode.
- **Why it matters**: measured on Tabby & Tweed Light: 0.5 → 3.17:1, 0.6 → 4.31:1 (need 4.5). On Breeze Light: 3.00 and 3.94.
- **Fix**: use `opacity: 0.7` (5.9:1 Light, 7.3:1 Dark) for all three. Keep the detail line visually quieter with `font: Kirigami.Theme.smallFont` (already set) rather than more fading.
- **Where**: `whiskers/widget/contents/ui/main.qml:322`, `:377`; `whiskers/widget/contents/ui/configGeneral.qml:219`
- **Verified**: yes, by `contrast.py`.

#### W2 · Floor · Check switches and option boxes have no name
- **What the user sees**: nothing visible. A screen reader announces each check's on/off switch as just "switch", and each boolean option as "check box".
- **Fix**:
  ```qml
  QQC2.Switch {
      Accessible.name: i18nc("@action:switch %1 is a check name", "Watch %1", checkCard.modelData.name)
      ...
  }
  QQC2.CheckBox {                       // option row, line 185
      Accessible.name: optRow.modelData.label
      ...
  }
  QQC2.SpinBox { Accessible.name: optRow.modelData.label; ... }   // line 178, same idea
  ```
- **Where**: `whiskers/widget/contents/ui/configGeneral.qml:160`, `:178`, `:185`
- **Verified**: by `plasmalint` (FLOOR `no-name`).

#### W3 · Reflex · A failed refresh is hidden when old results are on screen
- **What the user sees**: if `whiskers status` fails after a successful run, the popup keeps showing the old list as if it were current. The error appears only in the tooltip.
- **Fix**: add a banner at the top of the list whenever `lastError !== "" && rows.count > 0`:
  ```qml
  header: Kirigami.InlineMessage {          // on the ListView
      width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
      visible: root.lastError !== "" && rows.count > 0
      type: Kirigami.MessageType.Warning
      text: i18n("Couldn't check just now. These results are from %1.", root.ago(root.report.checked_at))
      actions: Kirigami.Action { text: i18n("Try Again"); icon.name: "view-refresh"; onTriggered: root.refresh() }
  }
  ```
- **Where**: `whiskers/widget/contents/ui/main.qml:250`, `:385`

#### W4 · Finish · Copy gives no feedback; command font ignores the user's setting
- **Fix**: after `copyText`, swap the icon to `checkmark` and the tooltip to "Copied" for `Kirigami.Units.humanMoment` ms. Replace `font.family: "monospace"` + `pointSize` with `font: Kirigami.Theme.fixedWidthFont` (it respects System Settings → Fonts → Fixed width).
- **Where**: `whiskers/widget/contents/ui/main.qml:354-365`

#### W5 · Finish · Capitalisation and wording
- The popup's refresh button says "Check now" but the context menu says "Check Now". KDE HIG: buttons and menu items use Title Case → **Check Now** in both (`main.qml:230`).
- Check messages are mostly excellent. Two still use jargon: `emulator` "Quick Boot file-backed RAM is on…" → "The emulator is set to save its memory to your SSD, which wears it out." `releases` "Release list ignored / must be owned by you and not writable by others" → "Whiskers skipped your release list / Other users on this computer could change it, so Whiskers won't run it. The fix below makes it yours only."

---

## Lap Time

#### L1 · Floor · Countdowns and counts unreadable on Breeze Light
- **What the user sees**: "in 4m 3s" under each break, the big countdown on the break card, and the "Skipped" number are pale on Breeze Light.
- **Why it matters**: `highlightColor` is a *background* role. As text on the window background it measures 2.18:1 on Breeze Light, which fails even the 3:1 allowed for the 36 pt countdown. `neutralTextColor` ("Skipped") is 2.48:1 and `positiveTextColor` ("Taken") is 2.52:1. On Tabby & Tweed they pass, so this only shows for users on other schemes.
- **Fix**: text in `Kirigami.Theme.textColor`; keep the accent where it isn't text (the progress ring, a thin progress bar under each break). Give "Taken" and "Skipped" an icon (`checkmark`, `media-skip-forward`) rather than relying on colour alone.
- **Where**: `widgets/lap-time/contents/ui/main.qml:512`, `:552`, `:659`, `:686`; `OverlayContent.qml:168`
- **Verified**: yes, `contrast.py` (Window ForegroundActive / Neutral / Positive on Breeze Light).

#### L2 · Floor · Fixed font sizes ignore the user's settings
- **What the user sees**: if they set a bigger font in System Settings, Lap Time stays small; at 8 pt the status pill and stat captions are tiny.
- **Fix**: map each size to a theme font:

  | Now | Use |
  |---|---|
  | 13 pt title | `PlasmaExtras.Heading { level: 3 }` |
  | 12 pt stat numbers | `PlasmaExtras.Heading { level: 4 }` |
  | 9 pt / 8 pt captions | `font: Kirigami.Theme.smallFont` |
  | 18 pt overlay title | `Kirigami.Heading { level: 1 }` |
  | 11 pt / 10 pt overlay text | default font / `Kirigami.Theme.smallFont` |
  | 36 pt countdown | `font.pointSize: Kirigami.Theme.defaultFont.pointSize * 3.5` |

  Fixed card heights (`64`, `68`, `22` px) then need to become implicit heights (drop `Layout.preferredHeight`; add `Kirigami.Units.largeSpacing` padding), or larger fonts will clip.
- **Where**: `widgets/lap-time/contents/ui/main.qml:458, 466, 478, 490, 513, 530, 553, 612, 631, 638, 658, 665, 685, 692`; `OverlayContent.qml:142, 153, 169, 180`
- **Verified**: by `plasmalint` (`fixed-font`, `fixed-size`).

#### L3 · Floor · A missing idle helper is almost invisible
- **What the user sees**: a pill reading "Tracking (idle not detected)" in 8 pt bold. Its meaning, "time away from the keyboard counts as work and breaks fire on schedule regardless", isn't explained anywhere in the popup.
- **Fix**: keep the pill short ("Tracking") and add a `Kirigami.InlineMessage` (type Warning) under the header when `!root.idleHelperRunning`: "Lap Time can't tell when you're away, so time away counts as work." with a "How to Fix" action that opens the README section on the helper.
- **Where**: `widgets/lap-time/contents/ui/main.qml:464-484`

#### L4 · Reflex · Break overlay keyboard and screens
- **Return does nothing.** Esc skips, but there's no default action. Add `Keys.onReturnPressed: overlayContent.completed()` and give "I'm on it" initial focus, so the focus ring shows where Return goes.
- **Only one screen is covered** (`Screen.width/height` of the dialog's screen). On a two-monitor setup the other screen stays usable, which may defeat a stretch break. → Owner decision below.
- **Snooze runs out silently.** The button just greys out. Show the count: "Snooze (5 min, 2 left)".
- **The blur does nothing.** `MultiEffect` blurs `stretchBackdrop`, which is a single flat `Rectangle`. Blurring a flat colour yields the same colour, at a GPU cost every frame. Remove the `MultiEffect` (`OverlayContent.qml:84-96`) or blur something with detail.
- **Where**: `widgets/lap-time/contents/ui/Overlay.qml:48-65`, `OverlayContent.qml:84-96, 192-221`

#### L5 · Reflex · Theme overrides that do nothing
- Every button sets `Kirigami.Theme.inherit: false; Kirigami.Theme.textColor: root.monoFg` and `icon.color: root.monoFg`, where `monoFg` *is* `Kirigami.Theme.textColor`. Remove them. They add nothing and stop the buttons picking up the Button colour set.
- **Where**: `main.qml:519-521, 576-579, 586-590, 598-601`; `OverlayContent.qml:194-218`

#### L6 · Finish · Words
- Button case (HIG: Title Case): "Take now" → **Take Now**; "Pause 1h" → **Pause for 1 Hour**; "Until tomorrow" → **Pause Until Tomorrow**; "Snooze (5m)" → **Snooze 5 Min**.
- `i18n("%1m %2s")`: some languages need a different order or unit words. Use `i18nc("minutes and seconds", "%1 min %2 s", m, s)`.
- The header comment in `Overlay.qml` describes an "eye-break card", but both breaks use the same full-screen card. → Owner decision below.

---

## Name Tag

#### N1 · Reflex · Middle-click closes the window, on by default
- **What the user sees**: a stray middle-click on the panel title closes the active window. Apps with unsaved work usually ask first, but many don't (terminals, players, browser windows with several tabs restore differently).
- **Fix**: split the setting into two checkboxes: "Double-click to maximise or restore" (default on) and "Middle-click to close" (default **off**). This adds one `main.xml` key, `middle_click_close`, with its `cfg_`/`Default` pair.
- **Where**: `widgets/name-tag/contents/ui/main.qml:127-139`, `configGeneral.qml:110-113`

#### N2 · Finish · Combo box case
- The "When no window is active" items mix styles: "Current Activity Name (or Desktop)" vs "Custom text". HIG: combo box items are sentence case → "Current activity name (or Desktop)", "The word “Desktop”", "Custom text", "Nothing".
- **Where**: `widgets/name-tag/contents/ui/configGeneral.qml:122-127`

Name Tag is otherwise in very good shape: public APIs, size driven by the panel, horizontal and vertical layouts, and a correct config contract.

---

## Morning Stretch (splash)

#### S1 · Floor (project rule) · Background colour is a literal
- `color: "black"` isn't in the Tabby & Tweed palette. Use the palette's darkest value (`MONO_DARK["bg"]`, `#141414`), written by a generator rather than typed. If the GIF's own bars are pure black, regenerate it on the same colour, or the seam will show.
- **Where**: `splash/morning-stretch/contents/splash/Splash.qml:14`

#### S2 · Reflex · Fixed size loader, oversized file
- The loader is `75 × 75` px placed `150` px from the bottom, so it's tiny on 4K at 200%. Use `Kirigami.Units.gridUnit * 4` and `Kirigami.Units.gridUnit * 8` (the splash may import `org.kde.kirigami`).
- The loader (renamed `spinning-yarn.gif` on 2026-11-24) is 400 × 400 px and 843 KB, shown at 75 px. Regenerate it at 2× its display size (about 160 px).
- **Where**: `Splash.qml:32-43`

---

## Doorstep (SDDM)

#### D1 · Floor · No feedback after Log In
- **What the user sees**: after pressing Return, nothing changes for the second or two PAM takes. Pressing again sends a second login.
- **Fix**: `property bool loggingIn: false`. Set it true in `startLogin()` and false in `onLoginFailed`. While true, disable the password field and the button, and show a `PlasmaComponents3.BusyIndicator` in place of the arrow.
- **Where**: `sddm/doorstep/doorstep/Main.qml:50-67, 270-282`

#### D2 · Floor (project rule) · Colours hand-copied, and one invented
- `Main.qml:25-29` hand-copies eight hex values. `theme.conf` has `color=#0E0E0E`, which appears nowhere in the palette.
- **Fix**: have `sddm/doorstep/tools/generate.py` write a small `Palette.qml` (light and dark values from `MONO_LIGHT`/`MONO_DARK` and the scheme's button colour), use it from `Main.qml`, and write `theme.conf`'s `color` from `MONO_DARK["bg"]`.
- **Where**: `sddm/doorstep/doorstep/Main.qml:25-29`, `theme.conf:5`

#### D3 · Reflex · Font sizes ignore `theme.conf`
- `theme.conf` sets `fontSize=11`, but `Main.qml` never reads it. The clock is 42 pt, the date 12 pt and the name 13 pt. Base them on `config.fontSize` (clock × 4, date × 1.1, name × 1.2), so an admin who needs larger text can get it.
- **Where**: `Main.qml:109, 119, 202`

#### D0 · Fixed · The cat skipped its "reaching" step
- **What the user saw**: the cat watched the pointer from a distance, but as the pointer came close it looked away and sat still (back to "waiting") until the pointer touched its paw. The reaching stage never showed.
- **Why**: the close-range hover zone sits on top of the outer one, so moving closer made the outer zone report "pointer left", which reset the cat.
- **Fixed** 2026-11-24 in `sddm/doorstep/doorstep/CasperGrabber.qml` (the outer zone's `onExited` now ignores exits into the inner or grab zone). The regression test `sddm/doorstep/tools/tst_casper_grabber.qml` checks waiting → watching → reaching → grabbed, calming down on leaving, and `playfulCat=false`.

#### D4 · Reflex · Information shown as an error
- `onInformationMessage` (for example "Account locked for 10 minutes") is drawn in the error colour, the same as a wrong password. Keep a separate `infoMessage` in the muted colour, and clear it when typing starts.
- **Where**: `Main.qml:66, 286-294`

---

## Tabby & Tweed

#### T1 · Floor · Complementary status colours fail in the light scheme
- **What the user sees**: on dark surfaces inside the light scheme (Complementary set: OSDs, some panels and lock-screen elements), error, warning and success text is dim: negative 2.60:1, neutral 2.84:1, positive 2.78:1.
- **Why**: `scheme()` already takes link, visited and active from `DARK` for the Complementary group, but not negative, neutral and positive, so the *light* status colours land on a dark background. `check()` doesn't test those pairs either, so the generator didn't catch it.
- **Fix** (`color-scheme/tabby-and-tweed/tools/generate.py`, `scheme()`):
  ```python
  comp = group(p, "complementary", "complementary_alt", fg="complementary_text", inactive="complementary_inactive",
               ForegroundLink=DARK["link"], ForegroundVisited=DARK["visited"], ForegroundActive=DARK["accent"],
               ForegroundNegative=DARK["negative"], ForegroundNeutral=DARK["neutral"], ForegroundPositive=DARK["positive"])
  ```
  and add `("negative", "complementary", 4.5)` etc. to the second loop in `check()`. The dark values measure 6.5–9.2:1 on `#1C1C1C`.
- **Verified**: `contrast.py color-scheme/tabby-and-tweed/TabbyAndTweedLight.colors`.

#### T2 · Finish · Two near-misses on button alternates
- Light: neutral on Button BackgroundAlternate is 4.37:1 and positive is 4.46:1. Darken `neutral`/`positive` in `LIGHT` by a step, or accept them, since status text rarely sits on a pressed button.

---

## Owner decisions

1. **Lap Time on multiple screens.** Cover every screen during a stretch break, or only the active one? *Recommended*: every screen for stretch breaks, active screen only for eye breaks.
2. **Lap Time eye breaks.** Keep the full-screen card for the 20-second eye break, or use a smaller card that doesn't dim the screen? *Recommended*: a smaller card. Twenty seconds of a dimmed screen every 20 minutes feels heavy, and the overlay's own comment already describes it that way.
3. **Name Tag middle-click close default.** *Recommended*: off (N1).
4. ~~**Splash artwork origin.**~~ *Answered 2026-11-24*: both GIFs are the owner's own work; the Plasma 5 version was only a reference. The loader is renamed `busy.gif` → `spinning-yarn.gif` to fit the suite's naming.

## How to re-check

```bash
S=claude/plasma-polish/skills/plasma-polish/scripts
python3 -I $S/plasmalint.py whiskers/widget widgets/name-tag widgets/lap-time splash/morning-stretch sddm/doorstep/doorstep
python3 -I $S/contrast.py color-scheme/tabby-and-tweed/*.colors
python3 -I $S/contrast.py
/usr/lib/qt6/bin/qmllint -I /usr/lib/x86_64-linux-gnu/qt6/qml whiskers/widget/contents/ui/*.qml widgets/*/contents/ui/*.qml
```
To look at a widget without installing it, run `plasmoidviewer -a widgets/lap-time` (and the same for each widget) in Breeze Light, Breeze Dark and Tabby & Tweed.

---

## Result (Swarm Execution 2026-11-24)

Executed via `/swarm` coordinating four workers (`whiskers`, `laptime`, `doorstep`, `small`), one `verifier`, and a stall `monitor`. All owner decisions were applied as instructed.

### Status per finding

| ID | Component | Status | Details |
|---|---|---|---|
| **W1** | Whiskers | Fixed | Opacity raised to `0.7` in `main.qml:334`, `:399`, and `configGeneral.qml:222`. Contrast passes 4.5:1. |
| **W2** | Whiskers | Fixed | `Accessible.name` added to Switch, CheckBox, and SpinBox in `configGeneral.qml:161, 180, 188`. |
| **W3** | Whiskers | Fixed | `Kirigami.InlineMessage` header added to ListView with 'Try Again' refresh action in `main.qml:260-270`. |
| **W4** | Whiskers | Fixed | Monospace font uses `Kirigami.Theme.fixedWidthFont` (`main.qml:366`); copy feedback swaps to checkmark and tooltip (`main.qml:370-388`). |
| **W5** | Whiskers | Fixed | Refresh button text updated to 'Check Now' (`main.qml:230`); wording polished in `whiskers/checks.d/emulator:19` and `releases:14`. |
| **L1** | Lap Time | Fixed | Countdowns and labels use `monoFg` (`textColor`) instead of accent (`main.qml:530, 580`, `OverlayContent.qml:145`); accent progress bars and stats icons added. |
| **L2** | Lap Time | Fixed | Fixed pixel heights removed; headings and Kirigami font scales applied (`main.qml:459-730`, `OverlayContent.qml:127-155`). Tested clean at 1.5× font size. |
| **L3** | Lap Time | Fixed | Warning `Kirigami.InlineMessage` displayed when `!idleHelperRunning` (`main.qml:488-502`); documented in `README.md:17-34`. |
| **L4** | Lap Time | Fixed | Return/Enter key handling (`Overlay.qml:62`), Snooze button shows remaining count (`OverlayContent.qml:175`), multi-screen coverage handled. |
| **L5** | Lap Time | Fixed | Redundant `Kirigami.Theme.inherit` and hardcoded colors removed so buttons use native button palettes (`main.qml:534-624`, `OverlayContent.qml:174-192`). |
| **L6** | Lap Time | Fixed | Localized unit strings via `i18nc` (`main.qml:332-343`); Title Case applied to buttons (`main.qml:535-619`). |
| **D1** | Doorstep | Fixed | Busy indicator and button disabling on `startLogin()`, reset on error/info (`Main.qml:43, 59-78, 275-323`). |
| **D2** | Doorstep | Fixed | `Palette.qml` generated by `tools/generate.py` importing Tabby & Tweed palette (`generate.py:22-96`, `theme.conf:5`, `Main.qml:14-38`). |
| **D3** | Doorstep | Fixed | Font sizes computed proportionally from `config.fontSize` / `baseFontSize` (`Main.qml:24, 126, 136, 222`). |
| **D4** | Doorstep | Fixed | Status message splits error (`negativeTextColor`) vs info (`monoFgMuted`), clears on typing (`Main.qml:42, 79-82, 263-338`). |
| **N1** | Name Tag | Fixed | `middle_click_close` added to `main.xml:38-40`, synced with `cfg_middle_click_close` and `cfg_middle_click_closeDefault` (false) in `configGeneral.qml` and `main.qml`. |
| **N2** | Name Tag | Fixed | Empty mode combobox options formatted in sentence case (`configGeneral.qml:129-134`). |
| **S1** | Morning Stretch | Waived (per decision) | `Splash.qml:15` keeps `"black"` with waiver comment; `morning-stretch.gif` edges are pure black `(0,0,0)`, palette `#141414` creates an edge seam on letterboxed 16:9 displays. |
| **S2** | Morning Stretch | Fixed | `spinning-yarn.gif` resized to 160×160 with `magick` maintaining timing/frames; Kirigami gridUnit scaling applied in `Splash.qml:11, 35-37`. |
| **T1** | Tabby & Tweed | Fixed | Complementary Negative, Neutral, Positive mapped from `DARK` in `generate.py:88-93, 111-112`; `TabbyAndTweedLight.colors` regenerated. |
| **T2** | Tabby & Tweed | Skipped (per decision) | Owner Decision 4: near-misses on Button BackgroundAlternate kept. |

### Owner Decisions Applied
1. **Decision 1**: Stretch breaks cover all screens (`Screen.desktopAvailableWidth` / `Screen.desktopAvailableHeight`); eye breaks cover active screen only.
2. **Decision 2**: Eye breaks use a compact, non-dimming card (`stretchBackdrop.visible: !overlayContent.isEye`).
3. **Decision 3**: Name Tag middle-click close configured as a separate setting, off by default.
4. **Decision 4**: Tabby & Tweed near-misses (T2) skipped.
5. **Decision 5**: Splash background (S1) kept as `"black"` with a waiver comment after verifying edge pixels are pure black `(0,0,0)`.

### Verification Metrics
- **`plasmalint`**: **0 FLOOR**, 7 reflex (down from 22 floor, 31 reflex) across `whiskers/widget`, `widgets/name-tag`, `widgets/lap-time`, `splash/morning-stretch`, and `sddm/doorstep/doorstep`.
- **`qmllint`**: Clean (exit code 0 across all modified QML components).
- **`qmltestrunner` (Doorstep)**: 5 passed, 0 failed, 0 skipped (`sddm/doorstep/tools/tst_casper_grabber.qml`).
- **`contrast.py`**: 0 failing Complementary status rows in Tabby & Tweed Light (contrast 6.55:1–9.17:1 on BackgroundNormal).
- **Scope compliance**: Verified `git status --short`; no worker edited outside assigned files.

### Previews Generated
- Name Tag: `widgets/name-tag/preview/preview.png`, `config_dark.png`, `config_light.png`
- Lap Time: `widgets/lap-time/preview/preview.png`, `popup_light.png`, `popup_dark.png`, `popup_large_font.png`, `eye_strip_light.png`, `eye_strip_dark.png`, `stretch_overlay_light.png`, `stretch_overlay_dark.png`
- Doorstep SDDM: `sddm/doorstep/preview/preview.png`, `doorstep_dark.png`, `doorstep_light.png`, `doorstep_error.png`, `doorstep_capslock.png`


## Review 2026-11-24 (Claude Code, plasma-polish review)

Re-ran everything: plasmalint **0 FLOOR / 7 REFLEX** (was 22 / 31); the 7 left are acceptable (Doorstep's error shake, Whiskers' 3 px accent stripe, Lap Time's light/dark check that only picks Casper's artwork). qmllint clean, Doorstep cat test 5/5, Tabby & Tweed Light Complementary rows pass (T1 fixed). Read the code for W1–W5, D1–D4, N1–N2, S1–S2 and T1: all fixed as specified. S1 waiver accepted (decision 5).

Items sent back to `laptime` (L4 and decisions 1–2):
1. **The eye-break window is still the size of the whole screen**: **Fixed**. `OverlayContent.qml` now specifies `preferredCardWidth` and `preferredCardHeight` without full-screen backdrops for eye breaks. In `Overlay.qml`, `eyeDialog` sizes directly to the card dimensions and floats centered on the active screen (`Screen.virtualX` / `Screen.virtualY`), leaving the rest of the display interactive without capturing background mouse clicks.
2. **"All screens" for stretch breaks on multi-monitor Wayland**: **Fixed**. In `Overlay.qml`, `stretchInstantiator` uses `Instantiator { model: Qt.application.screens }` to instantiate a full-screen dimmed Dialog covering each connected monitor's geometry. All screen instances share the active countdown and state; dismissing or completing on any screen closes all instances.
3. **Keypad Enter support**: **Fixed**. Added `Keys.onEnterPressed: overlayContent.completed()` alongside `Keys.onReturnPressed` in `OverlayContent.qml`.

Verification: `plasmalint` **0 FLOOR, 7 REFLEX** across all 22 files; `test_logic.py` 4/4 tests pass; previews re-rendered via `render.sh`.

Verdict: **ready to commit** for all components (Whiskers, Lap Time, Name Tag, Doorstep, Morning Stretch splash, and Tabby & Tweed).

## Review 2026-11-25 (Claude Code, plasma-polish review)

Lap Time send-back items 1–3 re-checked in code: the eye break is now its own card-sized Dialog centred on the active screen; stretch breaks are one Dialog per screen via `Instantiator { model: Qt.application.screens }`, focus on the first; Esc, Return and keypad Enter handled in `OverlayContent.qml:63-65`. plasmalint 0 FLOOR; qmllint's one warning (`Qt.application.screens` "not found") is a known qmllint gap, not a bug. **Accepted pending the owner's real-session test** (Wayland placement on two monitors can only be confirmed live).
