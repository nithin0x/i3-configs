#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
CONFIG_ROOT="$REPO_ROOT/configs"
ASSET_ROOT="$REPO_ROOT/assets"

INSTALL_PACKAGES=0
INSTALL_OBSIDIAN=0
APPLY_OBSIDIAN_CONFIG=0
SKIP_RELOAD=0

usage() {
  cat <<'EOF'
Usage: ./scripts/install.sh [options]

Options:
  --install-packages       Install desktop dependencies with apt
  --install-obsidian       Download and install the latest Obsidian .deb
  --apply-obsidian-config  Install the exported Obsidian app config
  --skip-reload            Skip wallpaper/i3/polybar/tmux reload steps
  -h, --help               Show this help message
EOF
}

log() {
  printf '[*] %s\n' "$*"
}

warn() {
  printf '[!] %s\n' "$*" >&2
}

die() {
  printf '[x] %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --install-packages)
      INSTALL_PACKAGES=1
      ;;
    --install-obsidian)
      INSTALL_OBSIDIAN=1
      ;;
    --apply-obsidian-config)
      APPLY_OBSIDIAN_CONFIG=1
      ;;
    --skip-reload)
      SKIP_RELOAD=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
  shift
done

need_cmd cp
need_cmd mv
need_cmd awk
need_cmd date

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$HOME/.config-backups/i3configs-repo-$TIMESTAMP"
mkdir -p "$BACKUP_ROOT"

backup_target() {
  local target="$1"
  local rel_path
  local backup_path

  if [ ! -e "$target" ] && [ ! -L "$target" ]; then
    return 0
  fi

  rel_path="${target#$HOME/}"
  if [ "$rel_path" = "$target" ]; then
    rel_path="${target#/}"
  fi

  backup_path="$BACKUP_ROOT/$rel_path"
  mkdir -p "$(dirname "$backup_path")"
  mv "$target" "$backup_path"
  log "Backed up $target -> $backup_path"
}

install_file() {
  local src="$1"
  local dest="$2"

  [ -f "$src" ] || die "Missing file: $src"
  backup_target "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
  log "Installed $dest"
}

install_dir() {
  local src="$1"
  local dest="$2"

  [ -d "$src" ] || die "Missing directory: $src"
  backup_target "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -a "$src" "$dest"
  log "Installed $dest"
}

install_packages() {
  need_cmd sudo
  need_cmd apt-get

  log "Installing desktop packages."
  sudo apt-get update
  sudo apt-get install -y \
    i3-wm \
    polybar \
    alacritty \
    rofi \
    feh \
    picom \
    tmux \
    fonts-jetbrains-mono \
    fonts-noto-color-emoji \
    playerctl \
    brightnessctl \
    flameshot \
    pavucontrol \
    thunar \
    network-manager-gnome \
    policykit-1-gnome \
    xclip
}

install_obsidian() {
  local tmpdir
  local version
  local deb_path

  need_cmd sudo
  need_cmd apt-get
  need_cmd curl

  tmpdir="$(mktemp -d)"
  version="$(curl -fsSL https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/desktop-releases.json | awk -F'"' '/"latestVersion"/ {print $4; exit}')"
  [ -n "$version" ] || die "Unable to determine latest Obsidian version."

  deb_path="$tmpdir/obsidian_${version}_amd64.deb"
  log "Downloading Obsidian $version."
  curl -fsSL -o "$deb_path" "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian_${version}_amd64.deb"
  sudo apt-get install -y "$deb_path"
  rm -rf "$tmpdir"
}

find_firefox_profile() {
  local profiles_ini="$HOME/.mozilla/firefox/profiles.ini"
  local profile_path

  [ -f "$profiles_ini" ] || return 1

  profile_path="$(awk -F= '
    /^\[Install/ {
      in_install=1
      next
    }
    /^\[/ && $0 !~ /^\[Install/ {
      in_install=0
    }
    in_install && $1 == "Default" {
      print $2
      exit
    }
  ' "$profiles_ini")"

  if [ -n "$profile_path" ]; then
    if [ -d "$HOME/.mozilla/firefox/$profile_path" ]; then
      printf '%s\n' "$HOME/.mozilla/firefox/$profile_path"
      return 0
    fi
    if [ -d "$profile_path" ]; then
      printf '%s\n' "$profile_path"
      return 0
    fi
  fi

  profile_path="$(awk -F= '
    /^\[Profile[0-9]+\]/ {
      if (section && is_default && path != "") {
        print path
        exit
      }
      section=1
      is_default=0
      path=""
      next
    }
    /^\[/ {
      if (section && is_default && path != "") {
        print path
        exit
      }
      section=0
      next
    }
    section && $1 == "Default" && $2 == "1" {
      is_default=1
    }
    section && $1 == "Path" {
      path=$2
    }
    END {
      if (section && is_default && path != "") {
        print path
      }
    }
  ' "$profiles_ini")"

  [ -n "$profile_path" ] || return 1

  if [ -d "$HOME/.mozilla/firefox/$profile_path" ]; then
    printf '%s\n' "$HOME/.mozilla/firefox/$profile_path"
    return 0
  fi

  if [ -d "$profile_path" ]; then
    printf '%s\n' "$profile_path"
    return 0
  fi

  return 1
}

install_firefox_theme() {
  local profile_dir
  local chrome_dir

  if ! profile_dir="$(find_firefox_profile)"; then
    warn "Firefox profile not found. Skipping Firefox theme install."
    return 0
  fi

  chrome_dir="$profile_dir/chrome"
  mkdir -p "$chrome_dir"

  backup_target "$profile_dir/user.js"
  backup_target "$chrome_dir/userChrome.css"
  backup_target "$chrome_dir/firefox-papirus-icon-theme"

  cp -a "$CONFIG_ROOT/firefox/user.js" "$profile_dir/user.js"
  cp -a "$CONFIG_ROOT/firefox/userChrome.css" "$chrome_dir/userChrome.css"
  cp -a "$CONFIG_ROOT/firefox/firefox-papirus-icon-theme" "$chrome_dir/firefox-papirus-icon-theme"
  log "Installed Firefox theme into $profile_dir"
}

reload_session() {
  local wallpaper="$HOME/Pictures/wallpapers/nord-hack-site.png"

  log "Refreshing wallpaper and live session."

  if command -v feh >/dev/null 2>&1; then
    feh --bg-fill "$wallpaper" >/dev/null 2>&1 || true
  fi

  if [ -n "${DISPLAY:-}" ] && command -v i3-msg >/dev/null 2>&1; then
    i3-msg reload >/dev/null 2>&1 || true
  fi

  if [ -n "${DISPLAY:-}" ] && [ -x "$HOME/.config/polybar/launch.sh" ]; then
    if command -v polybar-msg >/dev/null 2>&1; then
      polybar-msg cmd quit >/dev/null 2>&1 || true
    fi
    "$HOME/.config/polybar/launch.sh" >/dev/null 2>&1 || true
  fi

  if command -v tmux >/dev/null 2>&1 && tmux ls >/dev/null 2>&1; then
    tmux source-file "$HOME/.tmux.conf" >/dev/null 2>&1 || true
  fi
}

if [ "$INSTALL_PACKAGES" -eq 1 ]; then
  install_packages
fi

if [ "$INSTALL_OBSIDIAN" -eq 1 ]; then
  install_obsidian
fi

mkdir -p "$HOME/.config" "$HOME/.themes" "$HOME/Pictures/wallpapers"

install_dir "$CONFIG_ROOT/i3" "$HOME/.config/i3"
install_dir "$CONFIG_ROOT/polybar" "$HOME/.config/polybar"
install_dir "$CONFIG_ROOT/alacritty" "$HOME/.config/alacritty"
install_dir "$CONFIG_ROOT/rofi" "$HOME/.config/rofi"
install_dir "$CONFIG_ROOT/gtk-3.0" "$HOME/.config/gtk-3.0"
install_dir "$CONFIG_ROOT/gtk-4.0" "$HOME/.config/gtk-4.0"
install_dir "$CONFIG_ROOT/tmux" "$HOME/.config/tmux"
install_dir "$ASSET_ROOT/themes/Nordic" "$HOME/.themes/Nordic"

install_file "$CONFIG_ROOT/.tmux.conf" "$HOME/.tmux.conf"
install_file "$CONFIG_ROOT/.gtkrc-2.0" "$HOME/.gtkrc-2.0"
install_file "$ASSET_ROOT/wallpapers/nord-hack-site.png" "$HOME/Pictures/wallpapers/nord-hack-site.png"

chmod +x "$HOME/.config/polybar/"*.sh

install_firefox_theme

if [ "$APPLY_OBSIDIAN_CONFIG" -eq 1 ]; then
  install_dir "$CONFIG_ROOT/obsidian" "$HOME/.config/obsidian"
else
  warn "Skipping Obsidian config. Use --apply-obsidian-config if you want the exported app state."
fi

if [ "$SKIP_RELOAD" -eq 0 ]; then
  reload_session
fi

log "Install complete."
log "Backup saved at $BACKUP_ROOT"
