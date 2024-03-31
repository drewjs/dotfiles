local M = {
  'onsails/lspkind.nvim',
  event = {
    "InsertEnter",
    "CmdlineEnter",
  }
}

function M.config()
  local lspkind = require('lspkind')

  local symbol_map = {
    Text = "",
    Method = "󰆧",
    Function = "󰊕",
    Constructor = "",
    Field = "",
    Variable = "󰀫",
    Class = "󰠱",
    Interface = "",
    Module = "",
    Property = "",
    Unit = "",
    Value = "󰎠",
    Enum = "",
    Keyword = "󰌋",
    Snippet = "",
    Color = "",
    File = "",
    Reference = "󰜴",
    Folder = "",
    EnumMember = "",
    Constant = "󰏿",
    Struct = "󰙅",
    Event = "",
    Operator = "󱓉",
    TypeParameter = ""
  }

--  local symbol_map = {
--    Text = "",
--    Method = "",
--    Function = "",
--    Constructor = "",
--    Field = "ﰠ",
--    Variable = "",
--    Class = "ﴯ",
--    Interface = "",
--    Module = "",
--    Property = "ﰠ",
--    Unit = "塞",
--    Value = "",
--    Enum = "",
--    Keyword = "",
--    Snippet = "",
--    Color = "",
--    File = "",
--    Reference = "",
--    Folder = "",
--    EnumMember = "",
--    Constant = "",
--    Struct = "פּ",
--    Event = "",
--    Operator = "",
--    TypeParameter = ""
--  }

  lspkind.init {
    mode = 'symbol_text',
    symbol_map = symbol_map,
  }
end

return M
