#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
#   dotfiles installer — Catppuccin Mocha shell rice
#   Idempotent: safe to re-run.
# ════════════════════════════════════════════════════════════

set -Eeuo pipefail

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

# ── Error trap ──────────────────────────────────────────────
# Without this, `set -e` aborts silently — the user just sees the script stop.
on_error() {
  local rc=$?
  local line="${BASH_LINENO[0]:-?}"
  local cmd="${BASH_COMMAND:-?}"
  printf "\n%s✗ install.sh failed%s\n" >&2 "${RED}${BOLD}" "${RST}"
  printf "%s   exit code: %s%s\n"      >&2 "${RED}" "$rc"   "${RST}"
  printf "%s   at line:   %s%s\n"      >&2 "${RED}" "$line" "${RST}"
  printf "%s   command:   %s%s\n"      >&2 "${RED}" "$cmd"  "${RST}"
  case "$rc" in
    141) printf "%s   hint:      exit 141 = SIGPIPE — a pipeline reader (e.g. tar) closed before the writer (e.g. curl) finished%s\n" \
           >&2 "${YELLOW}" "${RST}" ;;
  esac
  exit "$rc"
}
trap on_error ERR

# ── Paths ───────────────────────────────────────────────────
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
OPT_DIR="$HOME/.local/opt"
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

mkdir -p "$BIN_DIR" "$OPT_DIR" "$ZSH_PLUGIN_DIR" "$TMUX_PLUGIN_DIR"
export PATH="$BIN_DIR:$PATH"

# ── Privilege helper ───────────────────────────────────────
# Empty when already root (common in Docker); 'sudo' otherwise.
# If we're not root and sudo isn't installed, pkg_install will error cleanly.
if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  SUDO=""   # flag as unavailable; handled in pkg_install
fi

# ── System package installer (may require sudo) ────────────
pkg_install() {
  local pkg="$1"
  if [[ "${EUID:-$(id -u)}" -ne 0 && -z "$SUDO" ]]; then
    fail "need root or sudo to install '$pkg' — install it manually and re-run"
  fi
  info "installing system package: $pkg${SUDO:+ (will prompt for sudo if needed)}"
  if   command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -qq && $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
  elif command -v dnf     >/dev/null 2>&1; then $SUDO dnf install -y "$pkg"
  elif command -v pacman  >/dev/null 2>&1; then $SUDO pacman -S --noconfirm "$pkg"
  elif command -v apk     >/dev/null 2>&1; then $SUDO apk add "$pkg"
  elif command -v zypper  >/dev/null 2>&1; then $SUDO zypper install -y "$pkg"
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
  # Parse "tag_name" via bash regex on the buffered response — no pipeline,
  # so no SIGPIPE risk when the JSON exceeds the pipe buffer (fastfetch's
  # release payload is ~50KB and triggered exit 141 in a grep -m1 | cut setup).
  local json
  json="$(curl -fsSL "https://api.github.com/repos/$1/releases/latest")" \
    || { warn "failed to fetch latest release for $1"; return 1; }
  [[ "$json" =~ \"tag_name\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]] \
    || { warn "no tag_name in response for $1"; return 1; }
  printf '%s\n' "${BASH_REMATCH[1]}"
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

install_pay_respects() {
  local tag; tag="$(gh_latest_tag iffse/pay-respects)"
  local vn="${tag#v}"
  curl -fsSL -o pr.tar.zst \
    "https://github.com/iffse/pay-respects/releases/download/${tag}/pay-respects-${vn}-x86_64-unknown-linux-musl.tar.zst"
  tar --zstd -xf pr.tar.zst
  install -m 0755 pay-respects "$BIN_DIR/pay-respects"
}

install_fastfetch() {
  # Download to a file rather than piping into `tar xz`. The release tarball is
  # ~5 MB; `tar` (via its gzip inflater) regularly closes stdin the instant it
  # hits the end of the gzip stream, while `curl` still has buffered bytes to
  # flush — the next write then gets SIGPIPE and curl exits 141. Writing to a
  # file sidesteps the race entirely.
  local tag; tag="$(gh_latest_tag fastfetch-cli/fastfetch)"
  curl -fsSL -o fastfetch.tar.gz \
    "https://github.com/fastfetch-cli/fastfetch/releases/download/${tag}/fastfetch-linux-amd64.tar.gz"
  tar xzf fastfetch.tar.gz
  install -m 0755 fastfetch-linux-amd64/usr/bin/fastfetch "$BIN_DIR/fastfetch"
}

# ── Tree-style installers (multi-file tools: $OPT_DIR/$name + symlinks) ─────
# install_bin assumes a single extracted binary — neovim and node ship full
# trees (bin/, lib/, share/), so these manage extraction and symlinks directly.

# xz ships as `xz-utils` on apt, `xz` elsewhere — ensure_pkg can't express that.
ensure_xz() {
  command -v xz >/dev/null 2>&1 && return
  if command -v apt-get >/dev/null 2>&1; then pkg_install xz-utils
  else                                         pkg_install xz
  fi
  command -v xz >/dev/null 2>&1 || fail "xz still not found after install"
}

install_neovim() {
  local dest="$OPT_DIR/nvim-linux-x86_64"
  if [[ -L "$BIN_DIR/nvim" && -x "$dest/bin/nvim" ]]; then
    skip "nvim already installed ($dest)"
    return
  fi
  info "installing neovim (github release)"
  local tmp; tmp="$(mktemp -d)"
  curl -fsSL -o "$tmp/nvim.tar.gz" \
    "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
  rm -rf "$dest"
  tar -C "$OPT_DIR" -xzf "$tmp/nvim.tar.gz"
  rm -rf "$tmp"
  ln -sfn "$dest/bin/nvim" "$BIN_DIR/nvim"
  ok "installed nvim → $BIN_DIR/nvim"
}

install_node() {
  local dest="$OPT_DIR/node"
  if [[ -L "$BIN_DIR/node" && -x "$dest/bin/node" ]]; then
    skip "node already installed ($dest)"
    return
  fi
  info "installing node LTS (nodejs.org) — required by coc.nvim"
  ensure_xz
  local tmp; tmp="$(mktemp -d)"
  local version
  curl -fsSL -o "$tmp/index.json" https://nodejs.org/dist/index.json
  version="$(sed -n 's/^{"version":"\(v[0-9.]*\)"[^}]*"lts":"[^"]\+".*/\1/p' "$tmp/index.json" | head -n1)"
  [[ -n "$version" ]] || fail "could not resolve latest node LTS version"
  local filename="node-${version}-linux-x64.tar.xz"
  curl -fsSL -o "$tmp/node.tar.xz" "https://nodejs.org/dist/${version}/${filename}"
  rm -rf "$dest"; mkdir -p "$dest"
  tar -C "$dest" --strip-components=1 -xJf "$tmp/node.tar.xz"
  rm -rf "$tmp"
  for cmd in node npm npx; do
    ln -sfn "$dest/bin/$cmd" "$BIN_DIR/$cmd"
  done
  ok "installed node → $BIN_DIR/node"
}

# ── Run ─────────────────────────────────────────────────────
printf "\n%s%s🍧 Ricing %s%s (dotfiles: %s)\n\n" \
  "${BOLD}" "${CYAN}" "${USER:-$(whoami)}" "${RST}" "$DOTFILES_DIR"

# 1. Symlinks FIRST — the most important step. If anything downstream fails,
#    you at least still have a working .zshrc pointing into the repo.
info "symlinking config files (backup → $BACKUP_DIR if needed)"
link_file "$DOTFILES_DIR/.zshrc"                         "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.config/starship.toml"          "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/.config/tmux/tmux.conf"         "$HOME/.config/tmux/tmux.conf"
link_file "$DOTFILES_DIR/.config/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
link_file "$DOTFILES_DIR/.config/nvim/init.vim"          "$HOME/.config/nvim/init.vim"
echo

# 2. System packages (zsh, tmux).
info "system packages"
ensure_pkg zsh
ensure_pkg tmux
ensure_pkg direnv
ensure_pkg zstd            # pay-respects ships .tar.zst archives
echo

# 3. User-space binaries.
info "binaries → $BIN_DIR"
install_bin starship     install_starship
install_bin zoxide       install_zoxide
install_bin eza          install_eza
install_bin bat          install_bat
install_bin fzf          install_fzf
install_bin fastfetch    install_fastfetch
install_bin pay-respects install_pay_respects
install_neovim                        # pinned to latest github release (apt's is too old)
install_node                          # coc.nvim needs node ≥ 16
echo

# 4. Zsh plugins.
info "zsh plugins → $ZSH_PLUGIN_DIR"
clone_repo https://github.com/zsh-users/zsh-autosuggestions     "$ZSH_PLUGIN_DIR/zsh-autosuggestions"
clone_repo https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting"
clone_repo https://github.com/Aloxaf/fzf-tab                    "$ZSH_PLUGIN_DIR/fzf-tab"
clone_repo https://github.com/zsh-users/zsh-completions         "$ZSH_PLUGIN_DIR/zsh-completions"
clone_repo https://github.com/catppuccin/zsh-syntax-highlighting "$ZSH_PLUGIN_DIR/catppuccin-syntax-highlighting"
echo

# 5. Tmux plugins + TPM.
info "tmux plugins → $TMUX_PLUGIN_DIR"
clone_repo https://github.com/tmux-plugins/tpm "$TMUX_PLUGIN_DIR/tpm"
clone_repo https://github.com/catppuccin/tmux  "$TMUX_PLUGIN_DIR/catppuccin/tmux" v2.1.3
if [[ -x "$TMUX_PLUGIN_DIR/tpm/bin/install_plugins" ]]; then
  "$TMUX_PLUGIN_DIR/tpm/bin/install_plugins" >/dev/null 2>&1 || warn "TPM install reported issues"
  ok "tmux plugins installed via TPM"
fi
echo

# 6. Neovim: vim-plug + plugins.
info "neovim plugins via vim-plug"
NVIM_PLUG="$HOME/.local/share/nvim/site/autoload/plug.vim"
if [[ -f "$NVIM_PLUG" ]]; then
  skip "vim-plug already installed"
else
  curl -fsSL --create-dirs -o "$NVIM_PLUG" \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  ok "installed vim-plug"
fi
if command -v nvim >/dev/null 2>&1; then
  nvim --headless +PlugInstall +qall >/dev/null 2>&1 || warn "PlugInstall reported issues"
  ok "nvim plugins installed"
fi
echo

# 7. Verify the symlinks actually point where we expect.
info "verifying symlinks"
verify_link() {
  local dst="$1" want="$2"
  if [[ -L "$dst" && "$(readlink -f "$dst")" == "$(readlink -f "$want")" ]]; then
    ok "$dst → $want"
  else
    warn "$dst does NOT point to $want (got: $(readlink "$dst" 2>/dev/null || echo 'missing'))"
  fi
}
verify_link "$HOME/.zshrc"                         "$DOTFILES_DIR/.zshrc"
verify_link "$HOME/.config/starship.toml"          "$DOTFILES_DIR/.config/starship.toml"
verify_link "$HOME/.config/tmux/tmux.conf"         "$DOTFILES_DIR/.config/tmux/tmux.conf"
verify_link "$HOME/.config/fastfetch/config.jsonc" "$DOTFILES_DIR/.config/fastfetch/config.jsonc"
verify_link "$HOME/.config/nvim/init.vim"          "$DOTFILES_DIR/.config/nvim/init.vim"
echo

# ── Optional: set zsh as default shell ──────────────────────
if [[ "${SHELL:-}" != *zsh ]] && command -v zsh >/dev/null 2>&1; then
  warn "current login shell is ${SHELL:-unknown}"
  printf "   run: %schsh -s \"\$(command -v zsh)\"%s to switch to zsh\n" "${BOLD}" "${RST}"
fi

if [[ -d "$BACKUP_DIR" ]]; then
  info "backups of replaced files saved to: $BACKUP_DIR"
fi

printf "\n%s%s✨ done — open a new terminal or run: exec zsh%s\n\n" "${BOLD}" "${GREEN}" "${RST}"
