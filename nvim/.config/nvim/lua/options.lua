-- [[ Setting options ]]
-- See `:help vim.opt`

-- Disable unused providers
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0

-- add filetypes
vim.filetype.add({ extension = { templ = "templ" } })

-- line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Save undo history
vim.opt.undofile = true

-- Indent width. A tab rendered at nvim's default 8 columns eats a third of the
-- herdr-nvim sidebar before any code shows; 4 keeps nesting readable in a pane
-- that narrow. vim-sleuth still detects tabs-vs-spaces per file.
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- gutter
vim.opt.colorcolumn = "80"

-- Enable mouse mode
vim.opt.mouse = "a"

-- Don't show the mode, since it's already in the status line
vim.opt.showmode = false

-- Sync clipboard between OS and Neovim
vim.opt.clipboard = "unnamedplus"

-- Enable break indent
vim.opt.breakindent = true

-- Case-insensitive searching UNLESS \C or capital letters
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Highlight on search
vim.opt.hlsearch = true

-- Keep signcolumn on by default
vim.opt.signcolumn = "yes"

-- Decrease update time
vim.opt.updatetime = 250

-- Decrease mapped sequence wait time (which-key popup sooner)
vim.opt.timeoutlen = 300

-- Configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Scroll context
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Wrap
vim.opt.wrap = true

-- Whitespace characters
vim.opt.list = true
vim.opt.listchars = { tab = "  ", trail = "·", nbsp = "␣" }

-- Preview substitutions live
vim.opt.inccommand = "split"

-- misc
vim.opt.showcmd = false
vim.opt.iskeyword:append("-")
