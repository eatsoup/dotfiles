# ════════════════════════════════════════════════════════════
#   ZSH — eatsoup's riced shell
# ════════════════════════════════════════════════════════════

# ── PATH ────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.deno/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"

# ── Environment ─────────────────────────────────────────────
export EDITOR="${EDITOR:-vim}"
export VISUAL="$EDITOR"
export LESS="-R --use-color -Dd+r -Du+b"
export MANPAGER="less -R --use-color -Dd+r -Du+b"
export LESSHISTFILE="-"
export FASTFETCH_CONFIG="$HOME/.config/fastfetch/config.jsonc"

# ── History ─────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt EXTENDED_HISTORY

# ── Shell behaviour ─────────────────────────────────────────
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt PROMPT_SUBST
setopt NO_BEEP
setopt NOTIFY

# ── Completions ─────────────────────────────────────────────
fpath=("$HOME/.zsh/plugins/zsh-completions/src" $fpath)
autoload -Uz compinit
compinit -d "$HOME/.zcompdump"

# Completion UI — colorful, case-insensitive, menu-select
zstyle ':completion:*' menu no
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose true
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format '%F{red}-- no matches --%f'
zstyle ':completion:*:git-checkout:*' sort false

# fzf-tab preview niceties
zstyle ':fzf-tab:complete:cd:*'     fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:z:*'      fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null'
zstyle ':fzf-tab:*' use-fzf-default-opts yes
zstyle ':fzf-tab:*' switch-group '<' '>'

# ── Theme ───────────────────────────────────────────────────
# Loads palette + FZF_DEFAULT_OPTS + BAT_THEME + syntax/autosuggest colors.
# Switch with the `theme` command (defined at the end of this file).
export DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
_theme_state="$HOME/.config/dotfiles/theme"
if [[ -r "$_theme_state" ]]; then
  _current_theme="$(<"$_theme_state")"
else
  _current_theme="catppuccin-mocha"
fi
[[ -r "$DOTFILES_DIR/themes/$_current_theme/shell.zsh" ]] && \
  source "$DOTFILES_DIR/themes/$_current_theme/shell.zsh"
unset _theme_state _current_theme

# ── Plugins ─────────────────────────────────────────────────
ZSH_PLUGINS="$HOME/.zsh/plugins"

# fzf-tab must come BEFORE zsh-syntax-highlighting, AFTER compinit
[[ -f "$ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh" ]] && source "$ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh"

[[ -f "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Ctrl+Space accepts the current autosuggestion.
# Terminals send NUL (^@) for Ctrl+Space; '^ ' is zsh's notation for it.
bindkey '^ ' autosuggest-accept

[[ -f "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ── fzf ─────────────────────────────────────────────────────
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh) 2>/dev/null || true
fi

# ── zoxide ──────────────────────────────────────────────────
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"

# ── direnv ──────────────────────────────────────────────────
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# ── Aliases ─────────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first --color=always'
  alias l='eza --icons --group-directories-first --color=always -lah --git'
  alias ll='eza --icons --group-directories-first --color=always -lh --git'
  alias la='eza --icons --group-directories-first --color=always -lah --git'
  alias lt='eza --icons --color=always --tree --level=2'
  alias ltr='eza --icons --color=always --tree'
fi
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never --style=plain' && alias catp='bat'
alias python='python3'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias ip='ip -c=auto'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias mkdir='mkdir -pv'
alias h='history'
alias reload='exec zsh'
alias rice='fastfetch'

# Git shortcuts
alias g='git'
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate --all'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gd='git diff'

# ── Starship prompt ─────────────────────────────────────────
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

# ── Theme switcher ──────────────────────────────────────────
# Usage:
#   theme            # list available themes + show current
#   theme <name>     # switch (persists across sessions)
theme() {
  emulate -L zsh
  local themes_dir="${DOTFILES_DIR:-$HOME/dotfiles}/themes"
  local state_dir="$HOME/.config/dotfiles"
  local state_file="$state_dir/theme"

  if [[ $# -eq 0 ]]; then
    local current="(unset)"
    [[ -r "$state_file" ]] && current="$(<"$state_file")"
    print -P "%F{cyan}current:%f $current"
    print -P "%F{cyan}available:%f"
    for t in "$themes_dir"/*(/N); do
      print "  ${t:t}"
    done
    return 0
  fi

  local name="$1"
  if [[ ! -d "$themes_dir/$name" ]]; then
    print -u2 "theme: unknown '$name' — run \`theme\` to list available themes"
    return 1
  fi

  mkdir -p "$state_dir" "$HOME/.config/tmux"
  print -- "$name" > "$state_file"
  ln -sfn "$themes_dir/$name/starship.toml" "$HOME/.config/starship.toml"
  ln -sfn "$themes_dir/$name/tmux.conf"     "$HOME/.config/tmux/theme.conf"

  # Live-update the current shell (these vars are read at use-time).
  [[ -r "$themes_dir/$name/shell.zsh" ]] && source "$themes_dir/$name/shell.zsh"

  # Reload tmux if we're inside it.
  if [[ -n "$TMUX" ]] && command -v tmux >/dev/null 2>&1; then
    tmux source "$HOME/.config/tmux/tmux.conf" >/dev/null 2>&1
    tmux display-message "theme: $name" >/dev/null 2>&1
  fi

  print -P "%F{green}✓%f theme switched to %F{cyan}$name%f"
}
compdef '_path_files -W "${DOTFILES_DIR:-$HOME/dotfiles}/themes" -/' theme 2>/dev/null || true

# ── Greeter + auto-tmux (interactive only) ──────────────────
if [[ $- == *i* ]]; then
  # Fastfetch only on a fresh login shell, once per tmux session
  if [[ -z "$TMUX" && -z "$FASTFETCH_SHOWN" ]]; then
    command -v fastfetch >/dev/null 2>&1 && fastfetch
    export FASTFETCH_SHOWN=1
  fi

  # Auto-launch tmux: attach to existing "main" session or create it.
  # Skipped inside VSCode integrated terminal, Claude Code, non-TTY shells,
  # and when TMUX/NO_TMUX are already set.
  if [[ -z "$TMUX" && -z "$NO_TMUX" && -z "$VSCODE_INJECTION" && -z "$CLAUDECODE" \
        && "$TERM_PROGRAM" != "vscode" && -t 0 && -t 1 ]]; then
    if command -v tmux >/dev/null 2>&1; then
      tmux attach -t main 2>/dev/null || exec tmux new -s main
    fi
  fi
fi
