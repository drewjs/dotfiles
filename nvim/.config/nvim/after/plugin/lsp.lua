local lsp = require('lsp-zero').preset({})

lsp.ensure_installed({
    'tsserver',
})

lsp.on_attach(function(client, bufnr)
    lsp.default_keymaps({buffer = bufnr})
end)

-- lsp.configure('tsserver', {
--     on_attach = function(client, bufnr)
--         print('hello tsserver')
--     end,
-- })

lsp.nvim_workspace()

lsp.setup()

local cmp = require('cmp')

cmp.setup({
    mapping = {
        ['<CR>'] = cmp.mapping.confirm({select = false}),
    }
})

vim.diagnostic.config({
    virtual_text = true,
})
