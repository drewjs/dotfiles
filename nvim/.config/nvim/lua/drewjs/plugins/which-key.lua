return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			spec = {
				{ "<leader>s", group = "[S]earch" },
				{ "<leader>g", group = "[G]it" },
				{ "<leader>u", group = "[U]I toggles" },
				{ "<leader>d", group = "[D]ocument / LSP" },
				{ "<leader>y", group = "[Y]ank clipboard" },
				{ "<leader>c", group = "[C]ode" },
				{ "<leader>r", group = "[R]efactor" },
				{ "<leader>w", group = "[W]orkspace" },
			},
		},
	},
}
