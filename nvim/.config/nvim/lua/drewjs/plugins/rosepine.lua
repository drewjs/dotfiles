local M = {
  'rose-pine/neovim',
  name = 'rose-pine',
  lazy = false,
  priority = 1000,
}

function M.config()
  local status, rosepine = pcall(require, "rose-pine")
  if not status then return end

  rosepine.setup({
    --- @usage 'auto'|'main'|'moon'|'dawn'
    variant = 'main',
    --- @usage 'main'|'moon'|'dawn'
    dark_variant = 'main',
    bold_vert_split = false,
    dim_nc_background = false,
    disable_background = true,
    -- disable_float_background = true,
    disable_italics = false,

    --- @usage string hex value or named color from rosepinetheme.com/palette
    groups = {
      background = 'base',
      background_nc = '_experimental_nc',
      panel = 'surface',
      panel_nc = 'base',
      border = 'pine',
      comment = 'muted',
      link = 'iris',
      punctuation = 'subtle',

      error = 'love',
      hint = 'iris',
      info = 'foam',
      warn = 'gold',

      headings = {
        h1 = 'iris',
        h2 = 'foam',
        h3 = 'rose',
        h4 = 'gold',
        h5 = 'pine',
        h6 = 'foam',
      }
      -- or set all headings at once
      -- headings = 'subtle'
    },

    highlight_groups = {
      TelescopeBorder = { fg = "highlight_high", bg = "none" },
      TelescopeNormal = { bg = "none" },
      TelescopePromptNormal = { bg = "base" },
      TelescopeResultsNormal = { fg = "subtle", bg = "none" },
      TelescopeSelection = { fg = "text", bg = "base" },
      TelescopeSelectionCaret = { fg = "rose", bg = "rose" },
    },
  })

  vim.cmd.colorscheme("rose-pine")
end

return M
