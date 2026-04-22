#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
#   dotfiles installer — Catppuccin Mocha shell rice
#   Idempotent: safe to re-run.
# ════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colour helpers ──────────────────────────────────────────
if [[ -t 1 ]]; then
  CYAN=$'\033[36m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'
  RED=$'\033[31m'; BOLD=$'\033[1m'; DIM=$'\033[2m'; RST=$'\033[0m'
else
  CYAN=; GREEN=; YELLOW=; RED=; BOLD=; DIM=; RST=
fi
info()  { printf "%s==>%s %s\n"       "${CYAN}${BOLD}" "${RST}" "$*"; }
ok()    { printf "%s ✓ %s%s\n"        "${GREEN}" "$*" "${RST}"; }
warn()  { printf "%s ! %s%s\n"        "${YELLOW}" "$*" "${RST}"; }
fail()  { printf "%s ✗ %s%s\n" >&2    "${RED}"   "$*" "${RST}"; exit 1; }
skip()  { printf "   %s· %s%s\n"      "${DIM}"   "$*" "${RST}"; }

# ── Paths ───────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
ZSH_PLUGIN_DIR="$HOME/.zsh/plugins"
TMUX_PLUGIN_DIR="$HOME/.config/tmux/plugins"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# ── Preflight ───────────────────────────────────────────────
require() { command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"; }
require curl
require git
require tar
require uname

ARCH="$(uname -m)"
OS="$(uname -s)"
[[ "$OS" == "Linux" ]]         || fail "this installer targets Linux (got: $OS)"
[[ "$ARCH" == "x86_64" ]]      || fail "this installer targets x86_64 (got: $ARCH)"

mkdir -p "$BIN_DIR" "$ZSH_PLUGIN_DIR" "$TMUX_PLUGIN_DIR"
export PATH="$BIN_DIR:$PATH"

# ── System package installer (requires sudo) ───────────────
# Installs a package using whichever package manager is present.
# Prompts for sudo password if not cached.
pkg_install() {
  local pkg="$1"
  info "installing system package: $pkg (will prompt for sudo if needed)"
  if   command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq && sudo apt-get install -y "$pkg"
  elif command -v dnf     >/dev/null 2>&1; then sudo dnf install -y "$pkg"
  elif command -v pacman  >/dev/null 2>&1; then sudo pacman -S --noconfirm "$pkg"
  elif command -v apk     >/dev/null 2>&1; then sudo apk add "$pkg"
  elif command -v zypper  >/dev/null 2>&1; then sudo zypper install -y "$pkg"
  else fail "no supported package manager found (apt/dnf/pacman/apk/zypper) — install '$pkg' manually and re-run"
  fi
}

ensure_pkg() {
  local cmd="$1" pkg="${2:-$1}"
  if command -v "$cmd" >/dev/null 2>&1; then
    skip "$cmd already installed ($(command -v "$cmd"))"
    return
  fi
  pkg_install "$pkg"
  command -v "$cmd" >/dev/null 2>&1 || fail "$cmd still not found after installing $pkg"
  ok "installed $cmd"
}

# ── Helpers ─────────────────────────────────────────────────
gh_latest_tag() {
  # $1 = owner/repo
  # Buffer the full response before parsing so grep -m1 can't SIGPIPE curl
  # (which shows as "curl: (23) Failure writing output to destination").
  local json
  json="$(curl -fsSL "https://api.github.com/repos/$1/releases/latest")" \
    || { warn "failed to fetch latest release for $1"; return 1; }
  printf '%s\n' "$json" | grep -m1 '"tag_name"' | cut -d '"' -f 4
}

# Install a binary if missing. Uses a download callback so each tool can
# fetch its own release artefact.
# $1 = binary name (also the command to test for)
# $2 = install function name
install_bin() {
  local name="$1" fn="$2"
  if command -v "$name" >/dev/null 2>&1; then
    skip "$name already installed ($(command -v "$name"))"
    return
  fi
  info "installing $name"
  local tmp; tmp="$(mktemp -d)"
  ( cd "$tmp" && "$fn" )
  rm -rf "$tmp"
  ok "installed $name"
}

# Clone a git repo into a target dir if not already present.
clone_repo() {
  local url="$1" dest="$2" ref="${3:-}"
  if [[ -d "$dest/.git" ]]; then
    skip "$(basename "$dest") already cloned"
    return
  fi
  info "cloning $(basename "$dest")"
  if [[ -n "$ref" ]]; then
    git clone --depth 1 --branch "$ref" "$url" "$dest" >/dev/null 2>&1
  else
    git clone --depth 1 "$url" "$dest" >/dev/null 2>&1
  fi
  ok "cloned $(basename "$dest")"
}

# Symlink $1 (target — lives in the dotfiles repo) into $2 (link path).
# If $2 already exists and is not already the correct symlink, back it up.
link_file() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] || fail "dotfiles source missing: $src"
  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" ]]; then
    local current; current="$(readlink -f "$dst" || true)"
    if [[ "$current" == "$(readlink -f "$src")" ]]; then
      skip "$dst already linked"
      return
    fi
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/"
    warn "backed up old symlink: $dst → $BACKUP_DIR/"
  elif [[ -e "$dst" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$dst" "$BACKUP_DIR/"
    warn "backed up existing file: $dst → $BACKUP_DIR/"
  fi

  ln -s "$src" "$dst"
  ok "linked $dst → $src"
}

# ── Binary installers ───────────────────────────────────────
install_starship() {
  curl -fsSL https://starship.rs/install.sh \
    | sh -s -- -b "$BIN_DIR" -y >/dev/null
}

install_zoxide() {
  curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
    | bash -s -- --bin-dir "$BIN_DIR" >/dev/null 2>&1
}

install_eza() {
  local tag; tag="$(gh_latest_tag eza-community/eza)"
  curl -fsSL "https://github.com/eza-community/eza/releases/download/${tag}/eza_x86_64-unknown-linux-gnu.tar.gz" \
    | tar xz
  install -m 0755 eza "$BIN_DIR/eza"
}

install_bat() {
  local tag; tag="$(gh_latest_tag sharkdp/bat)"
  curl -fsSL "https://github.com/sharkdp/bat/releases/download/${tag}/bat-${tag}-x86_64-unknown-linux-gnu.tar.gz" \
    | tar xz
  install -m 0755 "bat-${tag}-x86_64-unknown-linux-gnu/bat" "$BIN_DIR/bat"
}

install_fzf() {
  local tag; tag="$(gh_latest_tag junegunn/fzf)"
  local vn="${tag#v}"
  curl -fsSL "https://github.com/junegunn/fzf/releases/download/${tag}/fzf-${vn}-linux_amd64.tar.gz" \
    | tar xz
  install -m 0755 fzf "$BIN_DIR/fzf"
}

install_fastfetch() {
  local tag; tag="$(gh_latest_tag fastfetch-cli/fastfetch)"
  curl -fsSL "https://github.com/fastfetch-cli/fastfetch/releases/download/${tag}/fastfetch-linux-amd64.tar.gz" \
    | tar xz
  install -m 0755 fastfetch-linux-amd64/usr/bin/fastfetch "$BIN_DIR/fastfetch"
}

# ── Run ─────────────────────────────────────────────────────
printf "\n%s%s🍧 Ricing %s%s\n\n" "${BOLD}" "${CYAN}" "${USER}${RST}" "${BOLD}${RST}"

info "system packages (sudo may be required)"
ensure_pkg zsh
ensure_pkg tmux
echo

info "binaries → $BIN_DIR"
install_bin starship  install_starship
install_bin zoxide    install_zoxide
install_bin eza       install_eza
install_bin bat       install_bat
install_bin fzf       install_fzf
install_bin fastfetch install_fastfetch
echo

info "zsh plugins → $ZSH_PLUGIN_DIR"
clone_repo https://github.com/zsh-users/zsh-autosuggestions     "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
clone_repo https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
clone_repo https://github.com/Aloxaf/fzf-tab                    "$ZSH_PLUGIN_DIR/fzf-tab"
clone_repo https://github.com/zsh-users/zsh-completions         "$ZSH_PLUGIN_DIR/zsh-completions"
clone_repo https://github.com/catppuccin/zsh-syntax-highlighting "$ZSH_PLUGIN_DIR/catppuccin-syntax-highlighting"
echo

info "tmux plugins → $TMUX_PLUGIN_DIR"
clone_repo https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_DIR/tpm"
clone_repo https://github.com/catppuccin/tmux  "$TMUX_PLUGIN_DIR/catppuccin/tmux" v2.1.3
echo

info "symlinking config files (backup → $BACKUP_DIR if needed)"
link_file "$DOTFILES_DIR/.zshrc"                        "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.config/starship.toml"         "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/.config/tmux/tmux.conf"        "$HOME/.config/tmux/tmux.conf"
link_file "$DOTFILES_DIR/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
echo

info "installing tmux plugins via TPM"
if [[ -x "$TMUX_PLUGIN_DIR/tpm/bin/install_plugins" ]]; then
  "$TMUX_PLUGIN_DIR/tpm/bin/install_plugins" >/dev/null || warn "TPM install reported issues"
  ok "tmux plugins installed"
else
  warn "TPM binary missing — skipping"
fi
echo

# ── Optional: set zsh as default shell ──────────────────────
if [[ "${SHELL:-}" != *zsh ]] && command -v zsh >/dev/null 2>&1; then
  warn "current login shell is $SHELL"
  printf "   run: %schsh -s \"\$(command -v zsh)\"%s to switch to zsh\n" "${BOLD}" "${RST}"
fi

if [[ -d "$BACKUP_DIR" ]]; then
  info "backups of replaced files saved to: $BACKUP_DIR"
fi

printf "\n%s%s✨ done — open a new terminal or run: exec zsh%s\n\n" "${BOLD}" "${GREEN}" "${RST}"
