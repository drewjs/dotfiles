return {
	-- File type icons
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	-- Inline color highlighting
	{
		"brenoprata10/nvim-highlight-colors",
		event = { "BufReadPre", "BufNewFile" },
		opts = {},
	},

	-- Todo comment highlighting
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},

	-- Styled markdown rendering in-buffer
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = "markdown",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		opts = {},
	},

	-- Better code folding
	{
		"kevinhwang91/nvim-ufo",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "kevinhwang91/promise-async" },
		opts = {
			provider_selector = function()
				return { "treesitter", "indent" }
			end,
		},
		init = function()
			vim.opt.foldcolumn = "1"
			vim.opt.foldlevel = 99
			vim.opt.foldlevelstart = 99
			vim.opt.foldenable = true
		end,
	},
}
