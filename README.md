# dotfiles

Riced shell environment — Catppuccin Mocha across zsh, tmux, starship, fzf.

## Install

```sh
git clone <this-repo> ~/dotfiles
cd ~/dotfiles
./install.sh
```

The installer is idempotent — safe to re-run. Existing config files are moved to
`~/.dotfiles-backup/<timestamp>/` before being replaced with symlinks.

## What's in the box

| Tool       | Role                                           |
|------------|------------------------------------------------|
| zsh        | Shell (with autosuggestions, syntax-highlight, fzf-tab, completions) |
| starship   | Prompt (Catppuccin Mocha powerline)            |
| tmux       | Auto-attached on login, Catppuccin status bar  |
| fzf        | Fuzzy finder, themed                           |
| zoxide     | Smart `cd` replacement                         |
| eza        | `ls` replacement with icons & git status       |
| bat        | `cat` replacement with syntax highlighting     |
| fastfetch  | System info greeter on fresh terminals         |
| neovim     | Editor — vim-plug, gruvbox, coc, fzf, NERDTree |

All user binaries install to `~/.local/bin`. No `sudo` required.

## Layout

```
dotfiles/
├── install.sh
├── .zshrc
└── .config/
    ├── starship.toml
    ├── tmux/tmux.conf
    ├── fastfetch/config.jsonc
    └── nvim/init.vim
```

The repo mirrors `$HOME` — each file symlinks into the same relative path.

## Fonts

For the glyphs to render you need a Nerd Font in your terminal (Alacritty, etc.).
Recommended: [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads).

## Requirements

- Linux x86_64
- `curl`, `git`, `tar`, `zsh`, `tmux` (the installer checks for these)

## Uninstall

Remove the symlinks and restore backups:

```sh
rm ~/.zshrc ~/.config/starship.toml ~/.config/tmux/tmux.conf ~/.config/fastfetch/config.jsonc ~/.config/nvim/init.vim
# then restore whatever you want from ~/.dotfiles-backup/<timestamp>/
```
