local M = {
  "jose-elias-alvarez/null-ls.nvim",
  event = { "BufReadPost", "BufNewFile" },
}

function M.config()
  local null_ls = require "null-ls"
  local formatting = null_ls.builtins.formatting
  local diagnostics = null_ls.builtins.diagnostics
  local code_actions = null_ls.builtins.code_actions

  local augroup = vim.api.nvim_create_augroup("LspFormatting", {})

  local lsp_formatting = function(bufnr)
    vim.lsp.buf.format({
      filter = function(client)
        return client.name == "null-ls"
      end,
      bufnr = bufnr,
    })
  end

  null_ls.setup {
    debug = false,
    sources = {
      formatting.prettierd.with({
        env = {
          PRETTIERD_LOCAL_PRETTIER_ONLY = 1,
        },
      }),
      diagnostics.eslint_d.with {
        diagnostics_format = '#{m} (#{c})',
        env = {
          ESLINT_D_LOCAL_ESLINT_ONLY = 1,
        },
        --filter = function(diagnostic)
        --  return diagnostic.code ~= "prettier/prettier"
        --end,
      },
      code_actions.eslint_d.with {
        env = {
          ESLINT_D_LOCAL_ESLINT_ONLY = 1,
        },
      },
    },
    on_attach = function(client, bufnr)
      if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
          group = augroup,
          buffer = bufnr,
          callback = function()
            lsp_formatting(bufnr)
          end,
        })
      end
    end
  }

  vim.api.nvim_create_user_command(
    'DisableLspFormatting',
    function()
      vim.api.nvim_clear_autocmds({ group = augroup, buffer = 0 })
    end,
    { nargs = 0 }
  )
end

return M
