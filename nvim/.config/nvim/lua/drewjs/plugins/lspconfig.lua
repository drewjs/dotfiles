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

			-- Root the TypeScript server at the nearest package boundary, never at a monorepo root.
			--
			-- nvim-lspconfig's shipped lsp/vtsls.lua defines root_dir as a function that looks for a
			-- package-manager lockfile. In a pnpm workspace pnpm-lock.yaml exists only at the
			-- workspace root, so the default attaches one server to the whole tree -- verified:
			-- vtsls rooted at /Users/drewjs/work/selfserve (46GB) before this change. That puts every
			-- package's program in one Node heap and plants tsserver's recursive directory watchers
			-- over 37GB of .claude/worktrees.
			--
			-- `root_markers` CANNOT fix this: :help lsp-root_markers -- "Unused if root_dir is
			-- defined". root_dir has to be replaced outright.
			local function ts_root_dir(bufnr, on_dir)
				-- Deno guard, same intent as the shipped config.
				if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
					return
				end

				-- Nearest tsconfig/jsconfig is the project. Fall back to the nearest package.json so
				-- untyped JS packages still get a bounded root.
				local root = vim.fs.root(bufnr, { { "tsconfig.json", "jsconfig.json" }, { "package.json" } })
				if not root then
					return
				end

				-- Refuse to attach at a repo root that has no tsconfig of its own: that is the 46GB
				-- case. Stray scripts (scripts/*.mjs) lose LSP; biome still lints them.
				local git_root = vim.fs.root(bufnr, { ".git" })
				if git_root and root == git_root and vim.fn.filereadable(root .. "/tsconfig.json") == 0 then
					return
				end

				on_dir(root)
			end

			vim.lsp.config("vtsls", {
				root_dir = ts_root_dir,
				on_attach = function(_, bufnr)
					-- vtsls exposes fix_all / add_missing_imports / remove_unused / organize_imports
					-- as `source.*` code actions, and nvim only surfaces those when asked for by
					-- kind -- so <leader>ca alone will not show them. This restores what
					-- typescript-tools' expose_as_code_action provided. lsp/vtsls.lua ships no
					-- on_attach and no LspTypescriptSourceAction command (lsp/ts_ls.lua does).
					local function source_actions()
						vim.lsp.buf.code_action({
							context = {
								only = {
									"source.organizeImports",
									"source.fixAll.ts",
									"source.removeUnused.ts",
									"source.addMissingImports.ts",
								},
								diagnostics = {},
							},
						})
					end

					vim.api.nvim_buf_create_user_command(bufnr, "LspTypescriptSourceAction", source_actions, {
						desc = "TypeScript source actions (organize imports, fix all, remove unused, add missing)",
					})
					vim.keymap.set("n", "<leader>cA", source_actions, {
						buffer = bufnr,
						desc = "LSP: [C]ode [A]ction (TS source)",
					})
				end,
				settings = {
					vtsls = {
						-- Use the workspace's own TypeScript. selfserve pins 5.9.3 via its pnpm
						-- catalog and its .vscode/settings.json sets typescript.tsdk to
						-- ./node_modules/typescript/lib, so this keeps editor diagnostics identical
						-- to `pnpm typecheck`.
						autoUseWorkspaceTsdk = true,
						experimental = {
							completion = {
								-- Default is unbounded. Caps the payload for wide auto-import
								-- completions in a 4,181-file program with hoisted node_modules.
								entriesLimit = 100,
								enableServerSideFuzzyMatch = true,
							},
							maxInlayHintLength = 30,
						},
					},
					typescript = {
						tsserver = {
							-- Measured: apps/web cold `tsc --noEmit` peaks at 2.45 GiB. vtsls
							-- defaults to 3072, below that -- which is the condition its README
							-- names for the server dying on allocation failure, and a
							-- dying-and-restarting tsserver reads as "nvim hangs when I edit".
							-- Not set higher: this becomes --max-old-space-size, so an oversized
							-- heap only makes the eventual major GC pause longer.
							maxTsServerMemory = 6144,
							-- Project-wide error reporting over the whole program. Default false;
							-- pinned so it stays that way.
							experimental = { enableProjectDiagnostics = false },
						},
						-- "all" makes tsserver infer a name and type for every argument in the
						-- viewport on every scroll and edit, against a 1.9M-instantiation program.
						-- "literals" only annotates literal arguments, where hints actually help.
						inlayHints = {
							parameterNames = { enabled = "literals", suppressWhenArgumentMatchesName = true },
							parameterTypes = { enabled = false },
							variableTypes = { enabled = false },
							propertyDeclarationTypes = { enabled = false },
							functionLikeReturnTypes = { enabled = false },
							enumMemberValues = { enabled = true },
						},
						preferences = {
							-- vtsls takes VS Code-shaped settings: the key is `quoteStyle`, not the
							-- raw tsserver protocol's `quotePreference` that typescript-tools used.
							quoteStyle = "auto",
							autoImportFileExcludePatterns = {
								"vendor/**",
								"**/node_modules/**",
								".claude/worktrees/**",
							},
						},
					},
					javascript = {
						inlayHints = {
							parameterNames = { enabled = "literals", suppressWhenArgumentMatchesName = true },
						},
						preferences = {
							quoteStyle = "auto",
							autoImportFileExcludePatterns = {
								"vendor/**",
								"**/node_modules/**",
								".claude/worktrees/**",
							},
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
					"vtsls",
					"stylua",
					"prettierd",
					"biome",
				},
				run_on_start = true,
			})

			require("mason-lspconfig").setup({
				automatic_enable = {
					-- vtsls is the TypeScript server. lspconfig: "It is not recommended to enable
					-- both vtsls and ts_ls at the same time!" -- they would double-attach and run
					-- two tsservers. typescript-language-server may still be installed in Mason
					-- from before the swap; this keeps it inert. Remove it with :Mason if you like.
					exclude = { "ts_ls" },
				},
			})
		end,
	},
}
