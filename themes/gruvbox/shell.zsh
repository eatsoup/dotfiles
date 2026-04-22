# gruvbox — shell-level theming

export BAT_THEME='gruvbox-dark'

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#7c6f64"

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#ebdbb2'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#fb4934'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#fabd2f'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#b8bb26'
ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#b8bb26'
ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#b8bb26'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#83a598'
ZSH_HIGHLIGHT_STYLES[function]='fg=#83a598'
ZSH_HIGHLIGHT_STYLES[command]='fg=#b8bb26'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#8ec07c,italic'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#d3869b'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=#b8bb26'
ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#fe8019,italic'
ZSH_HIGHLIGHT_STYLES[path]='fg=#ebdbb2'
ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#d3869b'
ZSH_HIGHLIGHT_STYLES[path_prefix_pathseparator]='fg=#d3869b'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#fe8019'
ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#d3869b'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#fe8019'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#fe8019'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#d3869b'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#fabd2f'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#fabd2f'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#fabd2f'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#d3869b'
ZSH_HIGHLIGHT_STYLES[back-double-quoted-argument]='fg=#d3869b'
ZSH_HIGHLIGHT_STYLES[back-dollar-quoted-argument]='fg=#d3869b'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#d3869b'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#928374,italic'

export FZF_DEFAULT_OPTS="\
--color=bg+:#3c3836,bg:#282828,spinner:#fe8019,hl:#fb4934 \
--color=fg:#ebdbb2,header:#fb4934,info:#d3869b,pointer:#fe8019 \
--color=marker:#d3869b,fg+:#ebdbb2,prompt:#d3869b,hl+:#fb4934 \
--color=selected-bg:#504945 \
--color=border:#665c54,label:#ebdbb2 \
--height 60% --layout=reverse --border=rounded --margin=1 --padding=1 \
--prompt='  ' --pointer='' --marker='󰄲'"
