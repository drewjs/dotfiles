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
				capabilities = require("blink.cmp").get_lsp_capabilities({
					workspace = {
						-- PERF: nvim's macOS didChangeWatchedFiles backend is a single recursive
						-- FSEvents handle at the workspace root (vim/lsp/_watchfiles.lua ->
						-- vim/_watch.lua M.watch with uvflags.recursive). Registering it is O(1),
						-- but every filtering decision happens *inside* the Lua callback on the
						-- main loop -- so in ~/work/selfserve every one of ~2.8M files' changes
						-- crosses into it. The shipped exclude list covers node_modules but not
						-- .turbo/dist/.next/.git/index, i.e. exactly a turbo monorepo's churn.
						--
						-- Must be an explicit `false`: vim/lsp/client.lua deep-merges these on top
						-- of make_client_capabilities(), so you cannot remove a capability by
						-- omission. _watchfiles.M.register early-returns when it is falsy, so no
						-- watcher is created at all.
						--
						-- Cost: servers stop hearing about out-of-editor file changes. tsserver
						-- watches files itself (no loss); tailwindcss falls back to its own
						-- debounced, ignore-listed chokidar watcher (a gain); lua_ls/gopls may
						-- need :LspRestart after an out-of-editor dependency change.
						didChangeWatchedFiles = {
							dynamicRegistration = false,
							relativePatternSupport = false,
						},
					},
				}),
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

			-- Upstream's tailwindcss root_dir searches upward for tailwind.config.*/postcss.config.*
			-- and falls back to `.git`. Tailwind v4 needs no config file, so in a monorepo where only
			-- some packages use Tailwind that fallback lands on the repo root -- verified in
			-- selfserve: opening apps/mobile/src/App.tsx rooted tailwindcss at the 46GB tree and then
			-- resolved apps/auth's stylesheet for a mobile buffer. apps/mobile does not use Tailwind
			-- at all (only apps/auth and apps/web declare it).
			--
			-- Require positive evidence instead: the nearest ancestor that declares tailwindcss or
			-- ships a legacy config. No evidence -> do not attach, rather than attach at the root.
			local function tailwind_root_dir(bufnr, on_dir)
				local fname = vim.api.nvim_buf_get_name(bufnr)
				if fname == "" then
					return
				end
				for dir in vim.fs.parents(fname) do
					for _, ext in ipairs({ "js", "cjs", "mjs", "ts" }) do
						if vim.uv.fs_stat(vim.fs.joinpath(dir, "tailwind.config." .. ext)) then
							return on_dir(dir)
						end
					end
					local pkg = vim.fs.joinpath(dir, "package.json")
					if vim.uv.fs_stat(pkg) then
						local ok, content = pcall(vim.fn.readblob, pkg)
						if ok and tostring(content):find('"tailwindcss"', 1, true) then
							return on_dir(dir)
						end
					end
					-- Stop once we have considered the repo root; never attach above it.
					if vim.uv.fs_stat(vim.fs.joinpath(dir, ".git")) then
						return
					end
				end
			end

			-- Per-server configs
			vim.lsp.config("tailwindcss", {
				root_dir = tailwind_root_dir,
				-- lsp/tailwindcss.lua hard-sets dynamicRegistration = true, and a named config
				-- beats the "*" config in vim.lsp.config's merge order ("*", rtp, user) -- so the
				-- global strip above does not reach this server unless repeated here. tailwindcss
				-- is one of the two servers that actually registers bare `**/…` watchers, so this
				-- is the case that matters most. Verified: without this it still reported true.
				-- It falls back to its own debounced, ignore-listed chokidar watcher.
				capabilities = {
					workspace = {
						didChangeWatchedFiles = {
							dynamicRegistration = false,
							relativePatternSupport = false,
						},
					},
				},
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

			-- Resolve the workspace's own TypeScript, searching UPWARD from the LSP root.
			--
			-- `vtsls.autoUseWorkspaceTsdk` alone is not enough once root_dir is a package rather
			-- than the workspace root: it resolves typescript.tsdk relative to the workspace folder,
			-- and pnpm with nodeLinker=hoisted puts typescript only at the workspace root. Verified
			-- in selfserve: apps/web/node_modules/typescript does not exist, so vtsls silently fell
			-- back to its own bundled TypeScript -- a second copy of TS in memory, and a version
			-- that can drift from what `pnpm typecheck` and CI use.
			local function find_workspace_tsdk(root)
				if not root then
					return nil
				end
				for dir in vim.fs.parents(vim.fs.joinpath(root, "x")) do
					local lib = vim.fs.joinpath(dir, "node_modules", "typescript", "lib")
					if vim.uv.fs_stat(vim.fs.joinpath(lib, "tsserver.js")) then
						return lib
					end
				end
				return nil
			end

			vim.lsp.config("vtsls", {
				root_dir = ts_root_dir,
				before_init = function(_, config)
					local tsdk = find_workspace_tsdk(config.root_dir)
					if tsdk then
						config.settings = config.settings or {}
						config.settings.typescript = config.settings.typescript or {}
						config.settings.typescript.tsdk = tsdk
					end
				end,
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

			-- IMPORTANT: automatic_enable turns on EVERY server installed in Mason, and an enabled
			-- server's root_dir/before_init runs on buffers you would not expect -- the tailwindcss
			-- freeze fired on a markdown file. So an unused Mason package is a correctness risk, not
			-- clutter. Uninstalled deliberately: eslint-lsp (selfserve is biome-only, zero eslint
			-- configs, yet it attached to every .ts/.tsx buffer), templ (no .templ files),
			-- typescript-language-server (superseded by vtsls). Keep this list and Mason in sync.
			require("mason-lspconfig").setup({
				automatic_enable = {
					-- Belt and braces: vtsls is the TypeScript server, and lspconfig warns "It is not
					-- recommended to enable both vtsls and ts_ls at the same time!" -- they would
					-- double-attach and run two tsservers. typescript-language-server is uninstalled,
					-- so this only matters if something reinstalls it.
					exclude = { "ts_ls" },
				},
			})
		end,
	},
}
