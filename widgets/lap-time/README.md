# Lap Time (break reminder)

*Your lap time / the cat claiming your lap.*

**Status:** planned. Nothing to install yet.

A panel widget that counts how long you've been working. When it's break time, Casper strolls onto the screen and sits on your work until you take a break. It only counts real work: time spent idle or with the screen locked doesn't count.

## Breaks
| Break | Default | Based on | Overlay |
|---|---|---|---|
| **Eye break** | 20 s every 20 min | 20-20-20 rule (look about 6 m / 20 ft away) | Casper walks across the bottom of the screen, with a short countdown. Click-through, so it never blocks your work. |
| **Stretch break** | 5 min every 50 min | Common ergonomics guidance (a short break every 30–60 min) | Dimmed full-screen glass. Casper sits in the middle, stretches, then naps, with a countdown and a stretch tip. |

Both breaks are configurable: on/off, interval and length (1–240 min), plus a custom name per break.

## Rules for being a good cat
- **Snooze:** 5 min by default, at most 3 times. **Skip** is always one click away, or **Esc**. Breaks are never forced.
- **Idle reset:** if the screen is locked or you're idle for longer than the break length, the break counts as taken.
- **Don't disturb:** no full-screen overlay while Plasma's Do Not Disturb is on, during presentation mode, or while a full-screen app or call is active. A quiet panel badge appears instead.
- **Pause:** pause for 1 h, or until tomorrow, from the panel popup.
- **Stats:** the popup shows today's work time, breaks taken and breaks skipped. Stats stay local, with no network.
- **Looks:** follows the system light/dark theme. Casper is white, and in light mode he gets an outline (see `tasks/media.md`). Placeholder art is used until the media pass.
