-- colors
vim.opt.termguicolors = true

-- gutter
vim.opt.nu = true
vim.opt.relativenumber = true
vim.opt.colorcolumn = "80"

-- indent
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- backup
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- search
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- default position
vim.opt.scrolloff = 8

-- misc
vim.opt.guicursor = ""
vim.opt.isfname:append("@-@")
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 50
vim.opt.wrap = false
vim.o.completeopt = 'menuone,noselect'
