return {
	{
		"stevearc/oil.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		keys = {
			{ "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
			{
				"<leader>pv",
				function()
					require("oil").toggle_float()
				end,
				desc = "Oil float",
			},
		},
		opts = {
			delete_to_trash = true,
			skip_confirm_for_simple_edits = true,
			columns = { "icon" },
			view_options = {
				show_hidden = true,
				is_always_hidden = function(name)
					return name == ".." or name == ".git"
				end,
			},
			float = {
				padding = 2,
				max_width = 120,
				max_height = 40,
				border = "rounded",
			},
			keymaps = {
				["g?"] = { "actions.show_help", mode = "n" },
				["<CR>"] = "actions.select",
				["<C-v>"] = { "actions.select", opts = { vertical = true } },
				["<C-x>"] = { "actions.select", opts = { horizontal = true } },
				["<C-p>"] = "actions.preview",
				["<C-c>"] = { "actions.close", mode = "n" },
				["-"] = { "actions.parent", mode = "n" },
				["g."] = { "actions.toggle_hidden", mode = "n" },
				["q"] = { "actions.close", mode = "n" },
			},
			use_default_keymaps = false,
		},
	},
}
