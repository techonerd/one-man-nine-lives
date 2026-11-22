# Name Tag (window title widget)

*A name badge / a collar tag.* The window-title widget of the One Man Nine Lives suite: shows the active window's icon and title in the panel.

## Features
- **Plasma 6 native:** Uses public `org.kde.taskmanager` APIs only. Completely replaces the broken legacy *Window Title* widget without using private modules.
- **Customizable:** icon, title or both; icon size as a percentage of the panel thickness (resizes live); text as window title, application name, or both; length that fits the title (capped at a percentage of the screen width) or fills free panel space; bold titles.
- **Window actions:** follows only windows on its own screen (optional); double-click to maximise or restore, middle-click to close.
- **Smart empty state:** Shows your current Activity name (or "Desktop" / custom label) when no window is focused.
- **Follows system theme:** Kirigami/Plasma theme colors only. Adapts to horizontal and vertical panels.
- **Collar tag icon:** Custom symbolic badge icon included.

## Try / Install
```bash
kpackagetool6 -t Plasma/Applet -i .
```
Then add **Name Tag** to your panel from the widget explorer.

To uninstall:
```bash
kpackagetool6 -t Plasma/Applet -r com.github.techonerd.nametag
```
