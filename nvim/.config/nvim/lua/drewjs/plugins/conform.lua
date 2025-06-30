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
		config = function()
			local conform = require("conform")

			local js_format = {
				{ "prettierd", "prettier" },
				"biome",
			}

			conform.setup({
				format_on_save = function(bufnr)
					local disable_filetypes = {
						c = true,
						cpp = true,
						javascript = true,
						javascriptreact = true,
						typescript = true,
						typescriptreact = true,
					}

					-- Disable with a global or buffer-local variable
					if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
						return
					end

					return {
						timeout_ms = 1000,
						lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
					}
				end,
				formatters_by_ft = {
					javascript = js_format,
					javascriptreact = js_format,
					lua = { "stylua" },
					typescript = js_format,
					typescriptreact = js_format,
				},
				formatters = {
					biome = {
						condition = function(self, ctx)
							return vim.fs.find({ "biome.json" }, { path = ctx.filename, upward = true })[1]
						end,
					},
					prettier = {
						condition = function(self, ctx)
							return not vim.fs.find({ "biome.json" }, { path = ctx.filename, upward = true })[1]
						end,
					},
					prettierd = {
						condition = function(self, ctx)
							return not vim.fs.find({ "biome.json" }, { path = ctx.filename, upward = true })[1]
						end,
					},
				},
			})

			vim.api.nvim_create_user_command("FormatDisable", function(args)
				if args.bang then
					-- FormatDisable! will disable formatting just for this buffer
					vim.b.disable_autoformat = true
				else
					vim.g.disable_autoformat = true
				end
			end, {
				desc = "Disable autoformat-on-save",
				bang = true,
			})

			vim.api.nvim_create_user_command("FormatEnable", function()
				vim.b.disable_autoformat = false
				vim.g.disable_autoformat = false
			end, {
				desc = "Re-enable autoformat-on-save",
			})
		end,
	},
}
-- vim: ts=2 sts=2 sw=2 et
