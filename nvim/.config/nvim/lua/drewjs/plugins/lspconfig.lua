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
					map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
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

			-- Bounded replacement for nvim-lspconfig's find_tailwind_global_css().
			--
			-- Upstream (lsp/tailwindcss.lua) resolves Tailwind v4's global stylesheet by calling
			-- vim.fs.find() from the *git root* with no ignore list and limit=math.huge, then
			-- readblob()ing every .css/.scss/.pcss it finds. In ~/work/selfserve that is 5,678
			-- files across 46GB -- including 37GB of .claude/worktrees, which vim.fs.find sees
			-- because it does not respect .gitignore. It runs synchronously on the main loop in
			-- before_init, before the server starts, for every buffer tailwindcss claims (its
			-- filetype list includes markdown). Result: an unkillable multi-minute freeze.
			--
			-- Same intent, genuinely bounded.
			--
			-- NOTE: this deliberately uses vim.fs.dir, not vim.fs.find. vim.fs.find's predicate
			-- only filters *results* -- it does not prune *traversal*, so it still descends into
			-- every directory. A first attempt at this fix used vim.fs.find with a skip-list
			-- predicate and still hung on apps/mobile, which has 5.2GB of ios/ and 890MB of
			-- android/ inside the package: the walk never found its result limit, so it read the
			-- entire subtree anyway. vim.fs.dir's `skip` returns false to prune a directory before
			-- descending, which is what we actually need.
			local prune = {
				node_modules = true,
				[".git"] = true,
				[".claude"] = true,
				[".turbo"] = true,
				[".next"] = true,
				[".expo"] = true,
				dist = true,
				build = true,
				coverage = true,
				ios = true,
				android = true,
				vendor = true,
			}

			local function find_tailwind_css(root)
				if not root then
					return nil
				end
				for name, type_ in
					vim.fs.dir(root, {
						depth = 5,
						skip = function(dirname)
							return not prune[dirname]
						end,
					})
				do
					if type_ == "file" and name:match("%.css$") then
						local path = vim.fs.joinpath(root, name)
						local ok, content = pcall(vim.fn.readblob, path)
						if ok and tostring(content):find("tailwindcss", 1, true) then
							return path
						end
					end
				end
				return nil
			end

			-- Per-server configs
			vim.lsp.config("tailwindcss", {
				-- Replaces lspconfig's before_init so its unbounded scan never runs. Keep the
				-- tabSize behaviour it provided.
				before_init = function(params, config)
					config.settings = config.settings or {}
					config.settings.editor = config.settings.editor or {}
					config.settings.editor.tabSize = vim.lsp.util.get_effective_tabstop()
					config.settings.tailwindCSS = config.settings.tailwindCSS or {}
					config.settings.tailwindCSS.experimental = config.settings.tailwindCSS.experimental or {}
					local exp = config.settings.tailwindCSS.experimental
					if exp.configFile == nil then
						exp.configFile = find_tailwind_css(config.root_dir or params.rootPath)
					end
				end,
				-- Upstream claims 60+ filetypes, including markdown and mdx. Every one of them
				-- triggers before_init below, so trim to what we actually write Tailwind in.
				filetypes = {
					"html",
					"css",
					"scss",
					"javascript",
					"javascriptreact",
					"typescriptreact",
					"templ",
					"svelte",
					"vue",
				},
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
