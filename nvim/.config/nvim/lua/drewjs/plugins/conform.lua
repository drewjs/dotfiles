return {
	{ -- Autoformat
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>f",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = "",
				desc = "[F]ormat buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				local disable_filetypes = {
					c = true,
					cpp = true,
					javascript = true,
					javascriptreact = true,
					typescript = true,
					typescriptreact = true,
				}

				return {
					timeout_ms = 1000,
					lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
				}
			end,
			formatters_by_ft = {
				html = { { "prettierd", "prettier" } },
				javascript = { { "prettierd", "prettier" } },
				javascriptreact = { { "prettierd", "prettier" } },
				json = { { "prettierd", "prettier" } },
				jsonc = { { "prettierd", "prettier" } },
				lua = { "stylua" },
				markdown = { { "prettierd", "prettier" } },
				typescript = { { "biome", "prettierd", "prettier" } },
				typescriptreact = { { "biome", "prettierd", "prettier" } },
			},
			formatters = {
				prettierd = {
					env = {
						PRETTIERD_LOCAL_PRETTIER_ONLY = "1",
					},
				},
			},
		},
	},
}
-- vim: ts=2 sts=2 sw=2 et
