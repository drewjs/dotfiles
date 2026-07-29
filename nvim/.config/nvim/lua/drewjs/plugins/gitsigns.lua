return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				local gs = require("gitsigns")

				local function map(mode, keys, func, desc)
					vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = "Git: " .. desc })
				end

				-- Navigate hunks. Inside a diff, defer to the builtin ]c/[c.
				map("n", "]c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gs.nav_hunk("next")
					end
				end, "Next hunk")

				map("n", "[c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						gs.nav_hunk("prev")
					end
				end, "Previous hunk")

				-- Stage / reset
				map("n", "<leader>hs", gs.stage_hunk, "[h]unk [s]tage")
				map("n", "<leader>hr", gs.reset_hunk, "[h]unk [r]eset")
				map("v", "<leader>hs", function()
					gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "[h]unk [s]tage (selection)")
				map("v", "<leader>hr", function()
					gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, "[h]unk [r]eset (selection)")
				map("n", "<leader>hS", gs.stage_buffer, "[h]unk [S]tage buffer")
				map("n", "<leader>hR", gs.reset_buffer, "[h]unk [R]eset buffer")

				-- Inspect
				map("n", "<leader>hp", gs.preview_hunk, "[h]unk [p]review")
				map("n", "<leader>hb", function()
					gs.blame_line({ full = true })
				end, "[h]unk [b]lame line")
				map("n", "<leader>hd", gs.diffthis, "[h]unk [d]iff this")
				map("n", "<leader>hD", function()
					gs.diffthis("~")
				end, "[h]unk [D]iff against last commit")
			end,
		},
	},
}
