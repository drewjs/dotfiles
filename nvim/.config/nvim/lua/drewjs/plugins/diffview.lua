return {
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory", "DiffviewClose" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "[G]it [D]iff view" },
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "[G]it file [H]istory" },
		},
		opts = {},
	},
}
