# Doorstep (SDDM Login Theme)

*Coming home / waiting at the door.*

**Status:** v0.1.0 updated with transparent glass-like effect and Dark/Light dual coats.

Qt 6 SDDM theme featuring Casper waiting faithfully at the doorstep when you come home. Styled with a transparent frosted glass effect (glassmorphism) over Tabby & Tweed palettes.

## Features
- **Transparent Frosted Glass Design (Glassmorphism)**:
  - Translucent glass login card with subtle specular highlight rim.
  - Frosted glass capsule for password entry and touch-friendly controls.
  - Floating transparent glass dock for session and power buttons.
- **Dark & Light Mode Support**:
  - Live mode toggle button (☀️ / 🌙) in the top header.
  - **Dark Mode**: Nocturnal doorstep under warm amber lamp; Casper represented as **pure luminous white** (`#FFFFFF`).
  - **Light Mode**: Morning sunlit doorstep; Casper represented as **sleek complete inky black** (`#1B1714`).
- **Power Management**:
  - Dedicated buttons for **Sleep (Suspend)**, **Restart**, and **Shut Down** (**strictly NO Hibernate button** per spec).
- **Session & Keyboard**:
  - Wayland and X11 session switcher, live keyboard layout selector, and virtual keyboard toggle.
- **Safety & Feedback**:
  - Caps Lock warning indicator banner, error reporting, and rejection shake animation on wrong password.

## Testing & Preview in a Window (No Root Required)
```bash
sddm-greeter-qt6 --test-mode --theme ./sddm/doorstep/doorstep
```
*(Use the sun/moon button in the top right corner to toggle between Dark and Light glass styles live!)*
