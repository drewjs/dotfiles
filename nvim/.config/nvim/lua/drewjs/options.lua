-- colors
vim.opt.termguicolors = true

-- line numbers
vim.opt.nu = true
vim.opt.relativenumber = true

-- gutter
vim.opt.colorcolumn = "80"

-- indent
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

-- backups
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- search
vim.opt.hlsearch = false
vim.opt.incsearch = true

-- default position
vim.opt.scrolloff = 8

-- wrap
vim.opt.wrap = false
vim.opt.scrolloff = 8                           -- minimal number of screen lines to keep above and below the cursor
vim.opt.sidescrolloff = 8                       -- minimal number of screen columns to keep to the left and right of the cursor if wrap is `false`

-- netrw
vim.g.netrw_banner = 0			                    -- disable that anoying Netrw banner
vim.g.netrw_browser_split = 4			              -- open in a prior window
vim.g.netrw_winsize = 25
vim.g.netrw_altv = 1				                    -- open splits to the right
vim.g.netrw_liststyle = 3			                  -- treeview

-- misc
vim.opt.guicursor = ""
vim.opt.isfname:append("@-@")
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 50
vim.opt.completeopt = { "menuone", "noselect" } -- mostly just for cmp
vim.opt.fillchars.eob = " "                     -- show empty lines at the end of a buffer as ` ` {default `~`}
vim.opt.cmdheight = 1                           -- more space in the neovim command line for displaying messages
vim.opt.conceallevel = 0                        -- so that `` is visible in markdown files
vim.opt.pumheight = 10                          -- pop up menu height
vim.opt.showmode = false                        -- we don't need to see things like -- INSERT
vim.opt.splitbelow = true                       -- force all horizontal splits to go below current window
vim.opt.splitright = true                       -- force all vertical splits to go to the right of current window
vim.opt.showcmd = false                         -- hide (partial) command in the last line of the screen (for performance)
vim.opt.iskeyword:append "-"                    -- treats words with `-` as single words
vim.opt.guifont = "monospace:h17"               -- the font used in graphical neovim applications
vim.opt.laststatus = 0                          -- disables the status line
vim.opt.formatoptions:remove { "c", "r", "o" }  -- This is a sequence of letters which describes how automatic formatting is to be done

