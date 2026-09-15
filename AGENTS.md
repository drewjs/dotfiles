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

`herdr-plugins/` holds them all: the manifest at `.config/herdr-plugins/plugins`
(`<id> <owner/repo> <ref>`) and each plugin's config. Add a line, run
`herdr-plugins-sync`. Refs are pinned — Herdr has no `plugin update`, so a bumped
ref is a reinstall and the sync treats it as one.

Only a *server* restart starts a plugin, and `herdr server stop` closes the live
session — leave that one to the user.

Two CLI shapes `--help` omits: `herdr plugin install <owner/repo>` takes its flags
after the positional, and `plugin list --json` keys entries on `plugin_id` (the
envelope's `id` is the CLI request).

To turn a plugin off without uninstalling it, `herdr plugin disable <plugin-id>` (and
`enable` to reverse) — leave it in the manifest so the sync doesn't reinstall it.

Herdr writes its registry and source checkouts into its stow-symlinked config dir,
i.e. into this repo — both gitignored. A plugin's own config goes where the plugin
looks, rarely the dir `herdr plugin list` prints: Auto Title reads
`~/Library/Application Support/herdr-auto-title/config.env`, once, at startup.

A plugin can have a second half elsewhere — herdr-nvim ships an nvim plugin from
the same repo. Pin both halves to one tag so a bump moves them together: the
manifest for the herdr half, and `Lazy! update <plugin>` for the nvim one, since
`Lazy! install` leaves an already-cloned plugin on its old tag.

## Herdr

Mirrors `tmux.conf` binding-for-binding. Validate edits with `herdr config check` —
`herdr --default-config` isn't exhaustive (e.g. `copy_mode`, `swap_pane_*` are undocumented
there).

Seamless `ctrl+hjkl` nav is split across `nvim/.../multiplexer.lua`, `zsh/.zshrc`, and
`herdr/config.toml` (which deliberately leaves `ctrl+hjkl` unbound so nvim sees it first) —
herdr has no shell-side `is_vim` hook like tmux.
