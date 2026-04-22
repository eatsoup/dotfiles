# tokyo-night — shell-level theming

export BAT_THEME='base16'

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#414868"

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#c0caf5'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f7768e'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#e0af68'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#7aa2f7'
ZSH_HIGHLIGHT_STYLES[function]='fg=#7aa2f7'
ZSH_HIGHLIGHT_STYLES[command]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#7dcfff,italic'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#9ece6a'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#ff9e64,italic'
ZSH_HIGHLIGHT_STYLES[path]='fg=#c0caf5'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#ff9e64'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#ff9e64'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#ff9e64'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#e0af68'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#e0af68'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#e0af68'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#bb9af7'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#565f89,italic'

export FZF_DEFAULT_OPTS="\
--color=bg+:#292e42,bg:#1a1b26,spinner:#ff9e64,hl:#f7768e \
--color=fg:#c0caf5,header:#f7768e,info:#bb9af7,pointer:#ff9e64 \
--color=marker:#9d7cd8,fg+:#c0caf5,prompt:#bb9af7,hl+:#f7768e \
--color=selected-bg:#3b4261 \
--color=border:#545c7e,label:#c0caf5 \
--height 60% --layout=reverse --border=rounded --margin=1 --padding=1 \
--prompt='  ' --pointer='' --marker='󰄲'"
