local keymap = vim.keymap.set
local opts = { silent = true }

-- remap space as leader key
keymap("", "<Space>", "<Nop>", opts)
vim.g.mapleader = " "

-- convenience
keymap("n", "<leader>pv", vim.cmd.Ex)
keymap("i", "jj", "<Esc>")
keymap("i", "jk", "<Esc>")
keymap("n", "Q", "<nop>")
keymap("n", "q", "<nop>")

-- move selection up/down
keymap("v", "J", ":m '>+1<CR>gv=gv")
keymap("v", "K", ":m '<-2<CR>gv=gv")

-- movements
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")
keymap("n", "n", "nzzzv")
keymap("n", "N", "Nzzzv")
keymap("n", "J", "mzJ`z")

-- better paste
keymap({"n", "v"}, "<leader>d", [["_d]])
keymap("x", "<leader>p", [["_dP]])

-- copy to clipboard
keymap({"n", "v"}, "<leader>y", [["+y]])
keymap("n", "<leader>Y", [["+Y]])

-- refactor current word
keymap("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- executable script
keymap("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true })

-- tmux session
keymap("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- linter
keymap("v", "<leader>.", "<cmd>!eslint_d --stdin --fix-to-stdout<CR>gv", { noremap = true, silent = true })
keymap("n", "<leader>.", "mF<cmd>%!eslint_d --stdin --fix-to-stdout<CR>`F", { noremap = true, silent = true })

-- diagnostics
keymap('n', '[d', vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic message" })
keymap('n', ']d', vim.diagnostic.goto_next, { desc = "Go to next diagnostic message" })
keymap('n', '<leader>e', vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
keymap('n', '<leader>q', vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- telescope
keymap("n", "<leader>?", "<cmd>Telescope oldfiles<CR>", opts)
keymap("n", "<leader><space>", "<cmd>Telescope buffers<CR>", opts)
keymap('n', '<leader>/', function()
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, opts)
keymap("n", "<C-p>", "<cmd>Telescope git_files<CR>", opts)
keymap("n", "<leader>sf", "<cmd>Telescope find_files<CR>", opts)
keymap("n", "<leader>sh", "<cmd>Telescope help_tags<CR>", opts)
keymap("n", "<leader>sw", "<cmd>Telescope grep_string<CR>", opts)
keymap("n", "<leader>sg", "<cmd>Telescope live_grep<CR>", opts)
keymap("n", "<leader>sd", "<cmd>Telescope diagnostics<CR>", opts)

-- copilot
keymap("n", "<leader>co", "<cmd>Copilot panel<CR>", opts)

-- lsp
keymap("n", "<leader>lf", "<cmd>lua vim.lsp.buf.format{ async = true }<cr>", opts)
keymap('n', '<leader>ld', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<cr>', opts)

-- explorer
keymap({ "n", "i" }, "<C-b>", "<Esc><cmd>Lex<cr><cmd>vert resize 30<cr>")
