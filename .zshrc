# ════════════════════════════════════════════════════════════
#   ZSH — eatsoup's riced shell
# ════════════════════════════════════════════════════════════

# ── PATH ────────────────────────────────────────────────────
export DOTFILES_DIR=$HOME/git/dotfiles
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.deno/bin:$PATH"
export PATH="$PATH:/usr/local/go/bin"

# ── Environment ─────────────────────────────────────────────
export EDITOR="${EDITOR:-vim}"
export VISUAL="$EDITOR"
export LESS="-R --use-color"
export MANPAGER="less -R --use-color -Dd+r -Du+b"
export LESSHISTFILE="-"
export FASTFETCH_CONFIG="$HOME/.config/fastfetch/config.jsonc"
export XDG_CONFIG_HOME="$HOME/.config"

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

# ── Plugins ─────────────────────────────────────────────────
ZSH_PLUGINS="$HOME/.zsh/plugins"

# fzf-tab must come BEFORE zsh-syntax-highlighting, AFTER compinit
[[ -f "$ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh" ]] && source "$ZSH_PLUGINS/fzf-tab/fzf-tab.plugin.zsh"

# Catppuccin Mocha colours for zsh-syntax-highlighting
[[ -f "$ZSH_PLUGINS/catppuccin-syntax-highlighting/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh" ]] && \
  source "$ZSH_PLUGINS/catppuccin-syntax-highlighting/themes/catppuccin_mocha-zsh-syntax-highlighting.zsh"

[[ -f "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && source "$ZSH_PLUGINS/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#6c7086"
# Ctrl+Space accepts the current autosuggestion.
# Terminals send NUL (^@) for Ctrl+Space; '^ ' is zsh's notation for it.
bindkey '^ ' autosuggest-accept
bindkey '^[.' insert-last-word

[[ -f "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$ZSH_PLUGINS/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ── fzf ─────────────────────────────────────────────────────
if command -v fzf >/dev/null 2>&1; then
  # Catppuccin Mocha palette for fzf
  export FZF_DEFAULT_OPTS="\
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a \
--color=border:#585b70,label:#cdd6f4 \
--height 60% --layout=reverse --border=rounded --margin=1 --padding=1 \
--prompt='  ' --pointer='' --marker='󰄲'"
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
alias grep='grep --color=auto'

# ── Starship prompt ─────────────────────────────────────────
command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"

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

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[[ -s $HOME/.autojump/etc/profile.d/autojump.sh ]] && source $HOME/.autojump/etc/profile.d/autojump.sh

autoload -U compinit && compinit -u
eval "$(direnv hook zsh)"

if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer

eval $(thefuck --alias)

export GOPROXY=direct

alias vi=nvim
alias vim=nvim
alias k=kubectl
command -v kubectl >/dev/null 2>&1 && source <(kubectl completion zsh)

# Load custom config
test -f $DOTFILES_DIR/custom.zsh && source $DOTFILES_DIR/custom.zsh

