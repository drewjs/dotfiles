return {
	{
		"alexghergh/nvim-tmux-navigation",
		keys = {
			{ "<C-h>", "<cmd>NvimTmuxNavigateLeft<CR>", desc = "Navigate left" },
			{ "<C-j>", "<cmd>NvimTmuxNavigateDown<CR>", desc = "Navigate down" },
			{ "<C-k>", "<cmd>NvimTmuxNavigateUp<CR>", desc = "Navigate up" },
			{ "<C-l>", "<cmd>NvimTmuxNavigateRight<CR>", desc = "Navigate right" },
		},
		opts = { disable_when_zoomed = true },
	},
}
