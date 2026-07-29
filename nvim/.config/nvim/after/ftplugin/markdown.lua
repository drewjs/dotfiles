-- Workaround: Neovim 0.12 built-in ftplugin/markdown.lua calls vim.treesitter.start()
-- which crashes on markdown_inline injection parsing (nil node:range() call).
-- Stop treesitter highlighting and fall back to vim regex syntax.
vim.treesitter.stop()
