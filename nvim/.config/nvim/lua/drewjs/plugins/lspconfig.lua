return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",

			{ "j-hui/fidget.nvim", opts = {} },
			{ "folke/lazydev.nvim", ft = "lua", opts = {} },
		},
		config = function()
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("drewjs-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc)
						vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
					map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
					map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
					map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
					map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
					map(
						"<leader>ws",
						require("telescope.builtin").lsp_dynamic_workspace_symbols,
						"[W]orkspace [S]ymbols"
					)
					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
					map("K", vim.lsp.buf.hover, "Hover Documentation")
					map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
				end,
			})

			-- Global LSP config: capabilities for all servers
			vim.lsp.config("*", {
				capabilities = require("blink.cmp").get_lsp_capabilities(),
			})

			-- Per-server configs
			vim.lsp.config("tailwindcss", {
				settings = {
					tailwindCSS = {
						includeLanguages = {
							templ = "html",
						},
						experimental = {
							classRegex = {
								{ "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
								{ "cn\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
							},
						},
					},
				},
			})

			vim.lsp.config("gopls", {
				settings = {
					gopls = {
						completeUnimported = true,
						usePlaceholders = false,
						gofumpt = true,
						analyses = {
							unusedparams = true,
						},
					},
				},
			})

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace",
						},
					},
				},
			})

			require("mason").setup()

			require("mason-tool-installer").setup({
				ensure_installed = {
					"lua_ls",
					"gopls",
					"tailwindcss",
					"stylua",
					"prettierd",
					"biome",
				},
				run_on_start = true,
			})

			require("mason-lspconfig").setup({
				automatic_enable = {
					exclude = { "ts_ls" },
				},
			})
		end,
	},
}
