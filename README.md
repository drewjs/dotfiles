# dotfiles

Personal configuration files for macOS development environment.

## Install

On a fresh Mac, this installs Homebrew, clones the repo to `~/dotfiles`, and installs every tool with its config:

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/drewjs/dotfiles/main/install.sh)"
```

Add `install.sh` and flags after the quoted script to pick tools on the first run, for example `... install.sh --profile minimal`. Set `DOTFILES_DIR` to clone somewhere else.

From a clone:

```sh
./install.sh                    # first run: every tool; later runs: this machine's saved choice
./install.sh --profile minimal  # the tools tagged minimal in tools.txt
./install.sh --only nvim,tmux   # these tools, plus the tools they need
./install.sh --skip yabai,skhd  # every tool except these
./install.sh --pick             # choose from a numbered list
./install.sh --list             # show tools, profiles, and the saved choice
./install.sh --dry-run          # show what would change
```

- The choice is saved in `tools.local`, which git ignores. A bare rerun repeats it and changes nothing on a machine that is already set up.
- An existing file in the way of a link is moved to `~/.dotfiles-backup/<time>-<pid>/`, never overwritten.
- Deselecting a tool does not unlink or uninstall it. Run `stow -D <package>` and `brew uninstall` yourself.
- Machine-specific values and secrets go in gitignored local files, such as `~/.zshrc.local` (template in `zsh/.zshrc.local.example`).
- Manual steps: start the yabai and skhd services and grant their macOS permissions, and install the Ghostty font yourself.

To add a tool, add one line to `tools.txt`. If it has config, add a stow package that mirrors `$HOME`. CI reads `tools.txt`, so it tests the new tool too.

## Structure

- **alacritty/** - Terminal emulator configuration
- **bin/** - Custom scripts and executables
- **herdr/** - Terminal multiplexer (tmux alternative)
- **nvim/** - Neovim editor configuration with plugins
- **skhd/** - Simple hotkey daemon for macOS keyboard shortcuts
- **tmux/** - Terminal multiplexer configuration
- **yabai/** - Tiling window manager for macOS
- **zsh/** - Zsh shell configuration and profile
