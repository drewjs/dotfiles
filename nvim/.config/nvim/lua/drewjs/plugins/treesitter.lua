return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		dependencies = {
			"nvim-treesitter/nvim-treesitter-textobjects",
		},
		opts = {
			ensure_installed = {
				"bash",
				"c",
				"css",
				"diff",
				"go",
				"gomod",
				"html",
				"javascript",
				"json",
				"lua",
				"luadoc",
				"markdown",
				"markdown_inline",
				"query",
				"toml",
				"tsx",
				"typescript",
				"vim",
				"vimdoc",
				"yaml",
			},
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
				disable = { "markdown" }, -- nvim 0.12: markdown_inline injection parsing crash
			},
			indent = { enable = true },
		},
		config = function(_, opts)
			---@diagnostic disable-next-line: missing-fields
			require("nvim-treesitter.configs").setup(opts)
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		enabled = false, -- PERF: crashes treesitter on nvim 0.12 with injected langs (markdown, tsx)
		event = "BufReadPost",
		opts = {
			max_lines = 3,
		},
	},
}
