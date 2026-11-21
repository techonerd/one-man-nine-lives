# Whiskers

*Senses trouble before it lands.*

A cat's whiskers feel danger before it touches. On a man, they're the beard he forgot to trim.

Your system already knows when something goes wrong. It just says it in a language nobody reads: `kwin_wayland dumped core`, `Wakeup pending. Abort CPU freeze`, `fwupd-refresh.service: Failed with result 'exit-code'`. Whiskers **translates that into plain words**: what happened, what it means for you, and what to do. One calm notification per problem.

| The system says | Whiskers says |
|---|---|
| `hibernate requested from client 'kscreenlocker_g'` … `Wakeup pending. Abort CPU freeze` | **Hibernate didn't finish.** It was started from the lock screen, but the computer woke straight back up. That can look like a crash or a desktop restart; your open apps are fine. |
| `Process 60029 (asusd) dumped core` (SIGABRT) | **The ASUS control daemon crashed.** It stopped itself after an internal error and closed. Fan profiles, keyboard lighting and battery limit may stop working. |
| `/sys/block/nvme0n1/stat` write ticks ÷ writes = 117 ms | **Your system drive needs attention.** Writes take 117 ms on average (healthy SSDs: under 2 ms), so apps open slowly and the desktop can stutter. |

Whiskers is **read-only**: it explains and suggests, and it never changes your system.

## How it works
- **Live watch** (`whiskers-watch.service`) follows the system log and explains events as they happen:
  - app and desktop crashes
  - failed services
  - running out of memory
  - sleep or hibernate that didn't finish
  - drive errors
  - graphics resets
  - overheating
- **Checks** (`whiskers.timer`, a few minutes after login and then every few hours) look at slow-changing things: drive health, updates, disk pressure, your self-built tools and more.
- **Widget** (Plasma 6) shows four sections: *Needs your attention*, *What happened recently*, *Good to know* and *All good*. Every fix command has a copy button. It follows your light or dark colour scheme.
- **Quiet by design:**
  - Each problem is announced once, then at most once a day while it stays open.
  - A burst of problems becomes a single notification.
  - Repeated events are merged.

## Checks (plugins)
Each check is a small script in `checks.d/`. A check turns itself off on devices where it doesn't apply.

| Check | Watches | Works on |
|---|---|---|
| `services` | Failed system and user services, plus services you list under *Must always run* | any systemd distro |
| `updates` | Updates waiting too long; a restart needed after a kernel update | apt, dnf, pacman, zypper, flatpak |
| `disk` | Hardware errors, wear, heat, slow response | NVMe and SATA through UDisks (no root) |
| `io` | Apps stuck waiting for the disk, and the biggest writer | Linux 4.20+ (PSI) |
| `crashes` | Apps that crashed recently, and apps that keep crashing | systemd-coredump |
| `releases` | New GitHub releases of tools you build yourself (bring your own list) | anywhere |
| `emulator` | The Android emulator mirroring its RAM onto the SSD | only if `~/.android` exists |

`whiskers setup` (run by the installer) detects device-specific things. For example, on an ASUS laptop with asusctl it watches `asusd` and adds asusctl to your release list. Other devices simply don't get those.

### Bring your own tools to watch
Edit `~/.config/whiskers/releases.conf` (or click *Edit list…* in the widget settings):
```ini
[asusctl]
repo      = OpenGamingCollective/asusctl
installed = sed -n 's/^version *= *"\(.*\)"/\1/p' ~/asusctl/Cargo.toml | head -n 1
update    = cd ~/asusctl && git fetch --tags && git checkout {latest} && make && sudo make install
```
Whiskers only *shows* the update command; it never runs it.

### Write your own check
Put an executable script in `~/.config/whiskers/checks.d/<name>`. A check there overrides a bundled one with the same name. The script answers two commands:
```bash
#!/usr/bin/env bash
. "$WHISKERS_LIB/common.sh"
DESCRIBE='{"name":"Backups","description":"Reminds you when your last backup is old.","applies":true,
 "options":[{"key":"max_days","type":"int","default":7,"min":1,"max":90,"label":"Remind after","unit":"days"}]}'
run() {
  local age=$(( ($(date +%s) - $(stat -c %Y ~/backups/last 2>/dev/null || echo 0)) / 86400 ))
  if (( age > $(opt max_days 7) )); then
    emit backups warn "Your last backup is $age days old" "If the drive failed today, you'd lose $age days of work." "Run your backup now"
  else
    emit backups ok "Backups" "Last backup $age days ago."
  fi
}
plugin_main "$@"
```
It appears in `whiskers status` and in the widget settings automatically. Option types are `int`, `bool`, `string` and `file`. Any language works if it prints the same JSON (see `lib/common.sh`). Write messages for a human: say what happened and what it means for them.

Your own friendly names for programs go in `~/.config/whiskers/names.tsv` (same format as `lib/names.tsv`).

## Install
```bash
./install.sh        # user-level, no sudo; re-run to upgrade
```
Needs `jq`, `curl` and `notify-send`, which are usually installed already. Live alerts about system services need permission to read the system log: membership of the `adm` or `systemd-journal` group. `whiskers setup` tells you if that's missing.

## Use
```bash
whiskers status              # everything, explained
whiskers events              # what happened recently
whiskers plugins             # checks and their settings
whiskers config set disk.temp_warn 65
whiskers config set general.live false
whiskers debug disk          # raw output of one check
```

## Remove
```bash
./uninstall.sh               # keeps settings, your checks and history
./uninstall.sh --purge       # removes everything
```

## Privacy
Nothing about your machine leaves it. The only network use is an anonymous request to the GitHub API, at most every 12 hours per tool in your release list.
