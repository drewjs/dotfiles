# dotfiles

Personal configuration files for macOS development environment.

## Fresh Mac

`./setup` installs the Homebrew packages and links the Stow packages you pick. Press return at the prompt to take every tool. The choice is saved in `~/.config/dotfiles/tools` on that machine. Run `./setup` again and the linked configs stay as they are.

```
git clone https://github.com/drewjs/dotfiles.git
./dotfiles/setup
```

`./setup --tools nvim,zsh` installs that subset. `./setup --all --yes` installs every tool without a prompt. Add a tool by appending one row to `tools.tsv`. A row can depend on another tool. `zsh` depends on `starship` because the shell config starts it.

If a destination already exists and is not the repo file, setup moves it under `~/.local/share/dotfiles/backups/` and then links the repo file. Machine secrets stay in `~/.zshrc.local`. setup does not write that file.

A machine that is not using this installer can keep using Stow from the repo root.

## Structure

- **alacritty/** - Terminal emulator configuration
- **bin/** - Custom scripts and executables
- **herdr/** - Terminal multiplexer (tmux alternative)
- **nvim/** - Neovim editor configuration with plugins
- **skhd/** - Simple hotkey daemon for macOS keyboard shortcuts
- **tmux/** - Terminal multiplexer configuration
- **yabai/** - Tiling window manager for macOS
- **zsh/** - Zsh shell configuration and profile
