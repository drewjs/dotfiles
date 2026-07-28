return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		---@type snacks.Config
		opts = {
			bigfile = { enabled = true },
			notifier = { enabled = true, timeout = 3000 },
			quickfile = { enabled = false }, -- PERF: crashes treesitter on nvim 0.12 with markdown_inline injection
			statuscolumn = { enabled = true },
			words = { enabled = true },
			dim = { enabled = true },
			indent = { enabled = false }, -- PERF: scope computation crashes treesitter on nvim 0.12 with injected langs
			scratch = { enabled = true },
			gitbrowse = { enabled = true },
			toggle = { enabled = true },
		},
		keys = {
			{
				"<leader>.",
				function()
					Snacks.scratch()
				end,
				desc = "Scratch buffer",
			},
			{
				"<leader>gB",
				function()
					Snacks.gitbrowse()
				end,
				desc = "[G]it [B]rowse",
			},
			{
				"<leader>n",
				function()
					Snacks.notifier.show_history()
				end,
				desc = "[N]otification history",
			},
			{
				"<leader>un",
				function()
					Snacks.notifier.hide()
				end,
				desc = "Dismiss notifications",
			},
		},
		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
					Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
					Snacks.toggle.diagnostics():map("<leader>ud")
					Snacks.toggle.inlay_hints():map("<leader>uh")
					Snacks.toggle.dim():map("<leader>uD")
					Snacks.toggle.indent():map("<leader>ug")
				end,
			})
		end,
	},
}
