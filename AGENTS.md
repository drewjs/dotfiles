# AGENTS.md

macOS dotfiles managed with GNU Stow. Each top-level directory is a stow package.

## Structure

Each directory mirrors its target path under `$HOME`: XDG configs nest under `.config/`
(`nvim/.config/nvim/`), home-root dotfiles sit directly (`skhd/.skhdrc`), scripts go in
`bin/.local/bin/`. New tool: mirror this layout, then `stow <tool>`.

## Neovim

Requires nvim 0.12+ and the `tree-sitter-cli` Homebrew formula — `nvim-treesitter` tracks
`main`, not `master`, and every parser install fails without the CLI.

Tuned for large monorepos (huge worktree trees beside tiny source trees):

- Never walk downward from a project root unbounded. `vim.fs.find`'s predicate filters
  results, not traversal — use `vim.fs.dir` with `skip`. This is what freezes nvim hard
  enough to need `kill -9`.
- Root LSP servers per package, not repo root, with positive evidence before attaching.
  `root_markers` is ignored once a server config sets `root_dir` — replace `root_dir`
  directly, and note it also changes where `tsdk` resolves from.
- Keep Mason's `ensure_installed` pruned: `automatic_enable` turns on every installed
  server, and a stray server's `root_dir`/`before_init` can attach on unexpected filetypes.

## Herdr plugins

`herdr-plugins/` is the one package for every plugin: the manifest at
`.config/herdr-plugins/plugins` (`<id> <owner/repo> <ref>`, pinned — Herdr has no
`plugin update`) and each plugin's own config beside it. `herdr-plugins-sync`
applies it and keeps the `claude` agent integration current; it needs Go on PATH
because plugins build from source at install.

Plugins are global to the user and started by the *server*, so nothing runs until
`herdr server stop` — never run that unprompted, it closes the live session.
Auto Title reads `~/Library/Application Support/herdr-auto-title/config.env`, not
the config dir `herdr plugin list` prints, and only at startup.

## Herdr

Mirrors `tmux.conf` binding-for-binding. Validate edits with `herdr config check` —
`herdr --default-config` isn't exhaustive (e.g. `copy_mode`, `swap_pane_*` are undocumented
there).

Seamless `ctrl+hjkl` nav is split across `nvim/.../multiplexer.lua`, `zsh/.zshrc`, and
`herdr/config.toml` (which deliberately leaves `ctrl+hjkl` unbound so nvim sees it first) —
herdr has no shell-side `is_vim` hook like tmux.
