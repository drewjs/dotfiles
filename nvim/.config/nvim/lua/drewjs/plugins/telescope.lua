return {
	{
		"nvim-telescope/telescope.nvim",
		branch = "master", -- 0.1.x calls nvim-treesitter.parsers.ft_to_lang(), removed on treesitter `main`; master uses upstream vim.treesitter
		cmd = "Telescope",
		keys = {
			{
				"<C-p>",
				function()
					require("telescope.builtin").git_files()
				end,
				desc = "[P]roject files",
			},
			{
				"<leader>sh",
				function()
					require("telescope.builtin").help_tags()
				end,
				desc = "[S]earch [H]elp",
			},
			{
				"<leader>sk",
				function()
					require("telescope.builtin").keymaps()
				end,
				desc = "[S]earch [K]eymaps",
			},
			{
				"<leader>sf",
				function()
					require("telescope.builtin").find_files()
				end,
				desc = "[S]earch [F]iles",
			},
			{
				"<leader>ss",
				function()
					require("telescope.builtin").builtin()
				end,
				desc = "[S]earch [S]elect Telescope",
			},
			{
				"<leader>sw",
				function()
					require("telescope.builtin").grep_string()
				end,
				desc = "[S]earch current [W]ord",
			},
			{
				"<leader>sg",
				function()
					require("telescope.builtin").live_grep()
				end,
				desc = "[S]earch by [G]rep",
			},
			{
				"<leader>sd",
				function()
					require("telescope.builtin").diagnostics()
				end,
				desc = "[S]earch [D]iagnostics",
			},
			{
				"<leader>sr",
				function()
					require("telescope.builtin").resume()
				end,
				desc = "[S]earch [R]esume",
			},
			{
				"<leader>s.",
				function()
					require("telescope.builtin").oldfiles()
				end,
				desc = "[S]earch [R]ecent Files",
			},
			{
				"<leader><leader>",
				function()
					require("telescope.builtin").buffers()
				end,
				desc = "[S]earch [B]uffers",
			},
			{
				"<leader>/",
				function()
					require("telescope.builtin").current_buffer_fuzzy_find(
						require("telescope.themes").get_dropdown({ winblend = 10, previewer = false })
					)
				end,
				desc = "[S]earch [/] in current buffer",
			},
			{
				"<leader>s/",
				function()
					require("telescope.builtin").live_grep({
						grep_open_files = true,
						prompt_title = "Live Grep in Open Files",
					})
				end,
				desc = "[S]earch [/] in Open Files",
			},
			{
				"<leader>sn",
				function()
					require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "[S]earch [N]eovim files",
			},
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = function()
					return vim.fn.executable("make") == 1
				end,
			},
			{ "nvim-telescope/telescope-ui-select.nvim" },
			{ "nvim-tree/nvim-web-devicons" },
		},
		config = function()
			-- Search hidden files, but never inside .git.
			--
			-- ripgrep skips dot-directories by default, and telescope's defaults are a plain
			-- `rg --files` / `rg` invocation. In THIS repo every stow package keeps its content
			-- under a dot-directory (nvim/.config/nvim/..., bin/.local/bin/...), so find_files
			-- returned literally 2 results -- CLAUDE.md and README.md -- and grep found nothing.
			--
			-- Safe in big repos: rg still honours .gitignore and .git/info/exclude, so in
			-- ~/work/selfserve this goes 4,048 -> 4,161 files in 0.04s with zero results from the
			-- 37GB of .claude/worktrees.
			local hidden = { "--hidden", "--glob", "!**/.git/*" }

			local vimgrep_arguments = vim.list_extend({
				"rg",
				"--color=never",
				"--no-heading",
				"--with-filename",
				"--line-number",
				"--column",
				"--smart-case",
			}, hidden)

			require("telescope").setup({
				defaults = {
					vimgrep_arguments = vimgrep_arguments,
				},
				pickers = {
					find_files = {
						find_command = vim.list_extend({ "rg", "--files", "--color", "never" }, hidden),
					},
				},
				extensions = {
					["ui-select"] = {
						require("telescope.themes").get_dropdown(),
					},
				},
			})
			pcall(require("telescope").load_extension, "fzf")
			pcall(require("telescope").load_extension, "ui-select")
		end,
	},
}
