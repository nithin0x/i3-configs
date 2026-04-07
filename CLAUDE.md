# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A Nord-themed i3 window manager dotfiles collection for KVM/QEMU VMs. Running `scripts/install.sh` deploys configs to their correct locations and optionally installs packages.

## Installation

```bash
# Install configs only (backs up existing files automatically)
bash scripts/install.sh

# Install system packages first (apt-based distros)
bash scripts/install.sh --install-packages

# Other flags
bash scripts/install.sh --install-obsidian        # Download & install latest Obsidian .deb
bash scripts/install.sh --apply-obsidian-config   # Copy obsidian.json (machine-specific paths, skip by default)
bash scripts/install.sh --skip-reload             # Don't reload i3/polybar/tmux after install
```

The script creates timestamped backups at `~/.config-backups/i3configs-repo-YYYYMMDD-HHMMSS/` before overwriting anything.

## Architecture

All application configs live under `configs/` and map to their destinations:

| Source | Destination |
|--------|-------------|
| `configs/i3/` | `~/.config/i3/` |
| `configs/polybar/` | `~/.config/polybar/` |
| `configs/alacritty/` | `~/.config/alacritty/` |
| `configs/rofi/` | `~/.config/rofi/` |
| `configs/picom/` | `~/.config/picom/` |
| `configs/dunst/` | `~/.config/dunst/` |
| `configs/gtk-3.0/`, `configs/gtk-4.0/` | `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/` |
| `configs/tmux/` | `~/.config/tmux/` |
| `configs/.gtkrc-2.0` | `~/.gtkrc-2.0` |
| `configs/.tmux.conf` | `~/.tmux.conf` |
| `assets/themes/Nordic/` | `~/.themes/Nordic/` |
| `assets/wallpapers/` | `~/Pictures/wallpapers/` |

Firefox configs are installed into the detected profile directory from `~/.mozilla/firefox/profiles.ini`.

## Key Design Decisions

**Nord color palette** is used consistently across all apps. The palette is defined as variables in `configs/i3/config` and repeated in `configs/polybar/config.ini`, `configs/alacritty/theme.toml`, `configs/rofi/nord.rasi`, `configs/tmux/tmux.conf`, `configs/dunst/dunstrc`, and `configs/picom/picom.conf`. When changing colors, update all of these.

**Font**: JetBrainsMono Nerd Font in Polybar (for icons), JetBrains Mono everywhere else (terminal, GTK, rofi, dunst). Size varies: 7.5pt in Alacritty, 9pt in Polybar/dunst, 10pt in GTK, 11pt in Rofi.

**Polybar** uses Nerd Font icons (font-2) with inline `%{T3}` tags for icon rendering and `%{F#hex}` tags for colored icons. The VPN script uses `echo` (not `printf`) to avoid `%` conflicts with polybar format tags. Modules have `|` pipe separators and no background shading.

**Polybar scripts** in `configs/polybar/` provide click actions: `vpn-status.sh` auto-detects `tun0/wg0/vpn0/tap0`, `copy-vpn-ip.sh`/`copy-local-ip.sh` use `xclip`, `powermenu.sh` opens a rofi power menu. The brand module opens rofi on click.

**Rofi** uses rofi 2.0 syntax — `modes` not `modi`, `inherit` not `transparent` for background cascading. Theme file is `configs/rofi/nord.rasi`.

**picom** uses `xrender` backend with shadows disabled and no blur for VM compatibility.

**dunst** uses dunst 1.12+ syntax — `height = (0, 300)` and `offset = (10, 50)`.

**Obsidian vault path** in `configs/obsidian/obsidian.json` is hardcoded to `/home/igris/Documents/Obsidian Note's` — machine-specific, opt-in via `--apply-obsidian-config`.

**i3 modifier key** is `Mod4` (Super/Windows key). Workspace assignments: WS1=Firefox, WS2=Thunar, WS3=Obsidian. `workspace_auto_back_and_forth` is enabled.

**tmux prefix** is `Ctrl+Space` (secondary: `Ctrl+b`). Pane splits: `Prefix+h` (vertical), `Prefix+v` (horizontal). Vi copy mode with `v`/`y`.

**Wallpaper**: `nord-mountains.png` — set via `feh --bg-fill` in i3 autostart.
