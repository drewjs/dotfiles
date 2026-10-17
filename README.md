# dotfiles

Personal configuration files for macOS development environment.

## Set up a Mac

Clone the repo and run setup. That is the whole fresh-Mac command.

```bash
git clone https://github.com/drewjs/dotfiles.git "$HOME/dotfiles" && "$HOME/dotfiles/setup"
```

`setup` installs Homebrew when the Mac does not already have it. The first run then asks which tools this Mac should get. Press return to install every tool. The answer is saved in `~/Library/Application Support/dotfiles/selection`. The next run reads that file and leaves an up-to-date machine unchanged.

Run `setup --all` or `setup --only nvim,zsh` when you want to choose without the prompt.

Each tool is one card, `cards/<tool>`, plus the Stow package of the same name. Add a tool by adding that card. Leave `setup` alone.

Values that belong to one machine stay in `~/.zshrc.local`. That file is gitignored. Copy `zsh/.zshrc.local.example` and fill it in on the machine.

When Stow needs a path that already exists and is not already the matching symlink, `setup` copies that path to `~/Library/Application Support/dotfiles/backups/<timestamp>/` and then replaces the path with the symlink.

## Structure

- **alacritty/** - Terminal emulator configuration
- **bin/** - Custom scripts and executables
- **herdr/** - Terminal multiplexer (tmux alternative)
- **nvim/** - Neovim editor configuration with plugins
- **skhd/** - Simple hotkey daemon for macOS keyboard shortcuts
- **tmux/** - Terminal multiplexer configuration
- **yabai/** - Tiling window manager for macOS
- **zsh/** - Zsh shell configuration and profile
