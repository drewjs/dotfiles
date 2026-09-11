-- [[ Basic Keymaps ]]
-- See `:help vim.keymap.set()`

-- move selection up/down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- convenience
vim.keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode" })
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "q", "<nop>")

-- movements
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Page down centered" })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Page up centered" })
vim.keymap.set("n", "n", "nzzzv", { desc = "Search next centered" })
vim.keymap.set("n", "N", "Nzzzv", { desc = "Search prev centered" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines preserving cursor" })

-- better paste (visual-only to avoid blocking <leader>d* LSP keymaps)
vim.keymap.set("v", "<leader>d", [["_d]], { desc = "[D]elete without yank" })
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "[P]aste over without yank" })

-- NOTE: Substitute word is on S (normal mode), not <leader>s which is Telescope [S]earch prefix

-- executable script
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "Make file e[X]ecutable" })

-- Multiplexer: <C-h/j/k/l> pane navigation + <C-f> sessionizer (herdr or tmux)
local multiplexer = require("drewjs.multiplexer")
multiplexer.setup()
vim.keymap.set("n", "<C-f>", multiplexer.sessionizer, { desc = "Sessionizer" })

-- Clear search highlight on pressing <Esc> in normal mode
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Diagnostic keymaps
-- NOTE: [d and ]d are provided by Neovim 0.11+ by default
vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { desc = "Show diagnostic [E]rror messages" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostic [Q]uickfix list" })

-- Exit terminal mode
vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Disable arrow keys in normal mode
vim.keymap.set("n", "<left>", '<cmd>echo "Use h to move!!"<CR>')
vim.keymap.set("n", "<right>", '<cmd>echo "Use l to move!!"<CR>')
vim.keymap.set("n", "<up>", '<cmd>echo "Use k to move!!"<CR>')
vim.keymap.set("n", "<down>", '<cmd>echo "Use j to move!!"<CR>')

-- dmmulroy keymaps
vim.keymap.set({ "n", "v" }, "H", "^", { desc = "Start of line" })
vim.keymap.set({ "n", "v" }, "L", "$", { desc = "End of line" })
vim.keymap.set("n", "U", "<C-r>", { desc = "Redo" })
vim.keymap.set("n", "S", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Smart substitute word" })

-- Maximize/restore split (replaces vim-maximizer plugin)
vim.keymap.set("n", "<leader>m", "<C-w>|<C-w>_", { desc = "[M]aximize split" })
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "Equalize splits" })

-- NOTE: C-h/j/k/l window navigation handled by drewjs.multiplexer (above)
-- NOTE: <leader>pv file explorer handled by oil.nvim plugin
