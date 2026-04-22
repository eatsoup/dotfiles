# dotfiles

Riced shell environment — coordinated theme across zsh, tmux, starship, fzf, bat.
Ships with three themes (Catppuccin Mocha, Gruvbox, Tokyo Night); switch with the
`theme` command — see [Themes](#themes).

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
| starship   | Prompt (themed powerline)                      |
| tmux       | Auto-attached on login, themed status bar      |
| fzf        | Fuzzy finder, themed                           |
| zoxide     | Smart `cd` replacement                         |
| eza        | `ls` replacement with icons & git status       |
| bat        | `cat` replacement with syntax highlighting     |
| fastfetch  | System info greeter on fresh terminals         |

All user binaries install to `~/.local/bin`. No `sudo` required.

## Layout

```
dotfiles/
├── install.sh
├── .zshrc
├── .config/
│   ├── tmux/tmux.conf
│   └── fastfetch/config.jsonc
└── themes/
    ├── catppuccin-mocha/  (starship.toml, tmux.conf, shell.zsh)
    ├── gruvbox/
    └── tokyo-night/
```

The repo mirrors `$HOME` — each file symlinks into the same relative path.
`~/.config/starship.toml` and `~/.config/tmux/theme.conf` are symlinks into
`themes/<active>/` — the `theme` command just re-points them.

## Themes

Three coordinated themes. Each one sets the starship prompt, tmux status bar,
zsh-syntax-highlighting palette, zsh-autosuggestion fg, fzf colors, and `BAT_THEME`
in lockstep.

| Name               | Invoke            |
|--------------------|-------------------|
| Catppuccin Mocha (default) | `theme catppuccin-mocha` |
| Gruvbox            | `theme gruvbox`   |
| Tokyo Night        | `theme tokyo-night` |

```sh
theme                # list available + show current
theme gruvbox        # switch (persists across sessions)
```

The choice is persisted to `~/.config/dotfiles/theme`. Switching live-updates the
current shell and reloads tmux if you're inside it — no `exec zsh` needed.

> **Not covered:** terminal emulator color scheme. The statusbar and prompt will
> look correct, but for full visual match change the scheme in Windows Terminal /
> Alacritty / Ghostty / etc. yourself.

### Adding a new theme

Create `themes/<name>/` with three files — `starship.toml`, `tmux.conf`, and
`shell.zsh` — mirroring one of the existing themes (the templates are small and
self-contained).

## Fonts

For the glyphs to render you need a [Nerd Font](https://www.nerdfonts.com/font-downloads)
installed and selected in your terminal. Recommended: **JetBrainsMono Nerd Font**.

### Windows Terminal + WSL

If you see `?` or boxes instead of icons, the font must be installed on **Windows**
(the host), not inside WSL — Windows Terminal is the renderer, so `apt install fonts-*`
won't help.

1. Install the font on Windows. Either download the `.zip` from nerdfonts.com,
   unzip, select all `.ttf` files → right-click → **Install for all users**, or via
   PowerShell:
   ```powershell
   winget install --id DEVCOM.JetBrainsMonoNerdFont
   ```
2. Open Windows Terminal → `Ctrl+,` → your WSL profile (or Defaults) →
   **Appearance** → **Font face** → `JetBrainsMono Nerd Font` → Save.
3. Restart the terminal.

## Requirements

- Linux x86_64
- `curl`, `git`, `tar`, `zsh`, `tmux` (the installer checks for these)

## Uninstall

Remove the symlinks and restore backups:

```sh
rm ~/.zshrc ~/.config/starship.toml \
   ~/.config/tmux/tmux.conf ~/.config/tmux/theme.conf \
   ~/.config/fastfetch/config.jsonc
rm -rf ~/.config/dotfiles
# then restore whatever you want from ~/.dotfiles-backup/<timestamp>/
```
