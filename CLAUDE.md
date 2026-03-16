# CLAUDE.md

## Overview

macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow package containing configs for one application.

## Structure

Each directory mirrors the target path relative to `$HOME`:

- **XDG configs** nest under `.config/`: `nvim/.config/nvim/`, `tmux/.config/tmux/`, `alacritty/.config/alacritty/`
- **Home-root configs** place dotfiles directly: `skhd/.skhdrc`, `yabai/.yabairc`, `zsh/.zshrc`
- **Scripts** go in `bin/.local/bin/`

## Setup

```bash
# Install stow (if not already installed)
brew install stow

# Clone into home directory
git clone <repo> ~/dotfiles && cd ~/dotfiles

# Stow all packages
stow alacritty bin nvim skhd tmux yabai zsh

# Or stow a single package
stow nvim
```

## Adding a New Tool

1. Create a directory named after the tool: `mkdir -p <tool>/.config/<tool>`
2. Place config files mirroring their path relative to `$HOME`
3. Run `stow <tool>` to create symlinks

Example for a tool using XDG config:
```bash
mkdir -p starship/.config
cp ~/.config/starship.toml starship/.config/starship.toml
stow starship
```

Example for a home-root dotfile:
```bash
mkdir -p git
cp ~/.gitconfig git/.gitconfig
stow git
```

To remove symlinks: `stow -D <tool>`

## Neovim

Uses lazy.nvim for plugin management. Entry point is `nvim/.config/nvim/init.lua`.
Plugin configs live in `nvim/.config/nvim/lua/drewjs/plugins/`.

## Key Tools

- **alacritty** — terminal emulator (Catppuccin Mocha theme, BerkeleyMono font)
- **nvim** — editor with lazy.nvim, LSP, Telescope, Treesitter, Harpoon
- **tmux** — terminal multiplexer with custom statusline
- **skhd** — macOS hotkey daemon
- **yabai** — macOS tiling window manager
- **zsh** — shell config with Oh-My-Zsh, fzf, ripgrep
- **bin** — custom scripts (`tmux-sessionizer`, `present`/`unpresent`, etc.)
