# CLAUDE.md

## Overview

macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/). Each top-level directory is a stow package containing configs for one application.

## Structure

Each directory mirrors the target path relative to `$HOME`:

- **XDG configs** nest under `.config/`: `nvim/.config/nvim/`, `tmux/.config/tmux/`, `alacritty/.config/alacritty/`
- **Home-root configs** place dotfiles directly: `skhd/.skhdrc`, `yabai/.yabairc`
- **Scripts** go in `bin/.local/bin/`

## Setup

```bash
# Install stow (if not already installed)
brew install stow

# Required by Neovim: nvim-treesitter's `main` branch compiles parsers with the
# tree-sitter CLI. Without it EVERY parser install fails. Note this is a separate
# formula from the `tree-sitter` library.
brew install tree-sitter-cli

# Clone into home directory
git clone <repo> ~/dotfiles && cd ~/dotfiles

# Stow all packages
stow bin ghostty nvim skhd starship tmux yabai

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

Requires **nvim 0.12+** and the **`tree-sitter-cli`** Homebrew formula (see Setup).
`nvim-treesitter` tracks its `main` branch; `master` is frozen and does not support 0.12.

### Working in large monorepos

The config is tuned to stay responsive in repos whose directory tree is far bigger than
their source tree (e.g. one with 37GB of git worktrees beside 5MB of packages). Two rules
matter when editing LSP config here:

1. **Never walk downward from a project root unbounded.** `vim.fs.find`'s predicate filters
   *results*, it does not prune *traversal* — use `vim.fs.dir` with `skip` instead. Neither
   respects `.gitignore`. This is what froze nvim hard enough to need `kill -9`; see the
   `find_tailwind_css` comment in `lspconfig.lua`.
2. **Root LSP servers per package, not at the repo root**, and require positive evidence
   before attaching. `root_markers` is ignored when a server config defines `root_dir` —
   you must replace `root_dir`. Note that narrowing it also changes where `tsdk` resolves
   from; the two are coupled.

Unused Mason packages are a correctness risk, not clutter: `mason-lspconfig`'s
`automatic_enable` turns on **every** installed server, and a server's `root_dir` /
`before_init` runs on filetypes you would not expect. Keep Mason and `ensure_installed`
in sync.

## Key Tools

- **ghostty** — terminal emulator (Catppuccin Macchiato theme, BerkeleyMono font)
- **nvim** — editor with lazy.nvim, LSP, Telescope, Treesitter, Harpoon
- **tmux** — terminal multiplexer with Catppuccin Macchiato statusline (catppuccin/tmux plugin)
- **starship** — shell prompt
- **skhd** — macOS hotkey daemon
- **yabai** — macOS tiling window manager
- **bin** — custom scripts (`tmux-sessionizer`, `present`/`unpresent`, etc.)
