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
			-- Returning "" tells ufo not to attach to this buffer at all.
			--
			-- ufo otherwise attaches to everything, including scratch floats such as gitsigns'
			-- hunk preview (buftype=nofile). Its line cache then goes out of bounds against the
			-- float's shorter contents and its decoration provider throws on redraw:
			--   nvim-ufo/lua/ufo/model/buffer.lua:228: index out of bounds
			-- Same class of problem in diff mode, where the line mapping is not the buffer's own.
			provider_selector = function(_, filetype, buftype)
				local skip_ft = {
					[""] = true,
					help = true,
					qf = true,
					oil = true,
					TelescopePrompt = true,
					TelescopeResults = true,
					["gitsigns-blame"] = true,
					["gitsigns.blame"] = true,
					snacks_dashboard = true,
					snacks_notif = true,
					lazy = true,
					mason = true,
					checkhealth = true,
					diff = true,
				}
				if buftype ~= "" or skip_ft[filetype] then
					return ""
				end
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
