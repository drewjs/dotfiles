return {
	{
		"pmizio/typescript-tools.nvim",
		dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
		ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
		opts = {
			settings = {
				expose_as_code_action = { "fix_all", "add_missing_imports", "remove_unused", "organize_imports" },
				tsserver_file_preferences = {
					includeInlayParameterNameHints = "all",
					quotePreference = "auto",
				},
				publish_diagnostic_on = "insert_leave",
				-- Disabled: nvim-ts-autotag handles JSX close tags
				jsx_close_tag = { enable = false },
			},
		},
	},
	{
		"dmmulroy/ts-error-translator.nvim",
		ft = { "typescript", "typescriptreact" },
		opts = {},
	},
	{
		"dmmulroy/tsc.nvim",
		cmd = "TSC",
		opts = {},
	},
}
