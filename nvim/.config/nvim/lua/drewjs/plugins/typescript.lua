return {
	-- TypeScript LSP is `vtsls`, configured in lspconfig.lua (vim.lsp.config("vtsls", ...)).
	--
	-- Removed here:
	--   * pmizio/typescript-tools.nvim -- its default separate_diagnostic_server = true was never
	--     overridden, so it ran TWO full tsserver processes per project (measured ~1.0GB RSS each
	--     for apps/web). Upstream issue #228 reproduces this and was closed not_planned.
	--   * dmmulroy/tsc.nvim -- 21.9s blocking `tsc` on apps/web, and its results disagree with CI
	--     (apps/web typechecks via tsconfig.typecheck.json, which excludes stories).
	--     `pnpm typecheck` is the correct entry point. No keymap was bound to it.
	--
	-- See .scratch/nvim-stability/research/03-tsserver.md.
	{
		"dmmulroy/ts-error-translator.nvim",
		ft = { "typescript", "typescriptreact" },
		opts = {},
	},
}
