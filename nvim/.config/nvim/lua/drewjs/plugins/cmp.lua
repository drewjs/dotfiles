local M =   {
  'hrsh7th/nvim-cmp',
  dependencies = {
    'hrsh7th/cmp-nvim-lsp',
    'hrsh7th/cmp-path',
    'hrsh7th/cmp-buffer',
    'saadparwaiz1/cmp_luasnip',
    { 'L3MON4D3/LuaSnip', event = "InsertEnter" },
  },
  event = {
    "InsertEnter",
    "CmdlineEnter",
  },
}

function M.config()
  local cmp = require('cmp')
  local luasnip = require('luasnip')
  local lspkind = require('lspkind')

  --local function formatForTailwindCSS(entry, vim_item)
  --  if vim_item.kind == 'Color' and entry.completion_item.documentation then
  --    local _, _, r, g, b = string.find(entry.completion_item.documentation, '^rgb%((%d+), (%d+), (%d+)')
  --    if r then
  --      local color = string.format('%02x', r) .. string.format('%02x', g) .. string.format('%02x', b)
  --      local group = 'Tw_' .. color
  --      if vim.fn.hlID(group) < 1 then
  --        vim.api.nvim_set_hl(0, group, { fg = '#' .. color })
  --      end
  --      vim_item.kind = "●"
  --      vim_item.kind_hl_group = group
  --      return vim_item
  --    end
  --  end
  --  vim_item.kind = lspkind.symbolic(vim_item.kind) and lspkind.symbolic(vim_item.kind) or vim_item.kind
  --  return vim_item
  --end

  luasnip.config.setup {}

  cmp.setup {
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.close(),
      ['<C-y>'] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Replace,
        select = true
      }),
    }),
    sources = {
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
      { name = 'path' },
      { name = 'buffer' },
    },
    formatting = {
      format = lspkind.cmp_format({
        mode = 'symbol_text',
        maxwidth = 50,
        --menu = ({
        --  nvim_lsp = "[LSP]",
        --  path = "[Path]",
        --  buffer = "[Buffer]",
        --  luasnip = "[LuaSnip]",
        --}),
        --before = function(entry, vim_item)
        --  vim_item = formatForTailwindCSS(entry, vim_item)
        --  return vim_item
        --end
      })
    },
  }
end

return M
