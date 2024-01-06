local M = {
    "neovim/nvim-lspconfig",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        { "williamboman/mason.nvim", config = true },
        "williamboman/mason-lspconfig.nvim",
    },
}


local servers = {
    eslint = {
        packageManager = 'pnpm',
    },
    lua_ls = {
        Lua = {
            diagnostics = {
                globals = { 'vim' },
            },
            workspace = { checkThirdParty = false },
            telemetry = { enable = false },
        },
    },
    tailwindcss = {
        tailwindCSS = {
            experimental = {
                classRegex = {
                    { "cva\\(([^)]*)\\)", "[\"'`]([^\"'`]*).*?[\"'`]" },
                    { "cn\\(([^)]*)\\)",  "[\"'`]([^\"'`]*).*?[\"'`]" },
                },
            },
        },
    },
    tsserver = {},
    gopls = {
        gopls = {
            completeUnimported = true,
            usePlaceholders = false,
            gofumpt = true,
            analyses = {
                unusedparams = true,
            },
        },
    },
}


function M.config()
    local on_attach = function(client, bufnr)
        if client.name == "tsserver" then
            client.server_capabilities.documentFormattingProvider = false
        end

        local nmap = function(keys, func, desc)
            if desc then
                desc = 'LSP: ' .. desc
            end

            vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
        end

        local opts = { buffer = bufnr, silent = true }
        vim.keymap.set("i", "<C-h>", function() vim.lsp.buf.signature_help() end, opts)

        nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
        nmap('gr', require('telescope.builtin').lsp_references, '[G]oto [R]eferences')
        nmap('gi', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
        nmap('<leader>vd', vim.diagnostic.open_float, '[V]iew [D]iagnostics')
        nmap('<leader>vrr', vim.lsp.buf.references, '[R]efe[r]ences')
        nmap('<leader>vrn', vim.lsp.buf.rename, '[R]e[n]ame')
        nmap('<leader>vca', vim.lsp.buf.code_action, '[C]ode [A]ction')
        nmap('<leader>gt', vim.lsp.buf.type_definition, '[T]ype Definition')
        nmap('<leader>ds', require('telescope.builtin').lsp_document_symbols, '[D]ocument [S]ymbols')
        --vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
        nmap('<leader>ws', require('telescope.builtin').lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')
        nmap('K', vim.lsp.buf.hover, 'Hover Documentation')
        nmap('<leader>aa', vim.diagnostic.setqflist, '[A]ll Workspace Diagnostics')
        nmap('<leader>ae', function() vim.diagnostic.setqflist({ severity = "E" }) end, '[A]ll Workspace [E]rrors')
        nmap('<leader>aw', function() vim.diagnostic.setqflist({ severity = "W" }) end, '[A]ll Workspace [W]arnings')

        -- Create a command `:Format` local to the LSP buffer
        vim.api.nvim_buf_create_user_command(bufnr, 'Format', function(_)
            vim.lsp.buf.format()
        end, { desc = 'Format current buffer with LSP' })

        local augroup = vim.api.nvim_create_augroup("LspFormatting", {})
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = augroup,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.format()
            end,
        })
    end

    -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
    local capabilities = vim.lsp.protocol.make_client_capabilities()
    capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

    -- Ensure the servers above are installed
    local mason_lspconfig = require('mason-lspconfig')

    mason_lspconfig.setup {
        ensure_installed = vim.tbl_keys(servers),
    }

    mason_lspconfig.setup_handlers {
        function(server_name)
            require('lspconfig')[server_name].setup {
                capabilities = capabilities,
                on_attach = on_attach,
                settings = servers[server_name],
            }
        end,
    }

    vim.diagnostic.config({ virtual_text = true })
end

return M
