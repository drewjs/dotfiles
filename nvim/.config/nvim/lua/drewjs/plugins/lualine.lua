return {
  {
    'nvim-lualine/lualine.nvim',
    event = { "VimEnter", "InsertEnter", "BufReadPre", "BufAdd", "BufNew", "BufReadPost", "ColorScheme" },
    opts = {
      options = {
        theme = 'rose-pine',
        icons_enabled = false,
        --component_separators = '|',
        --section_separators = '',
      },
      sections = {
        lualine_a = { 'mode' },
        lualine_b = { 'branch' },
        lualine_c = { {
          'filename',
          file_status = true, -- displays file status (readonly status, modified status)
          path = 0 -- 0 = just filename, 1 = relative path, 2 = absolute path
        } },
        lualine_x = {
          { 'diagnostics', sources = { "nvim_diagnostic" }, symbols = { error = 'E ', warn = 'W ', info = 'I ',
            hint = 'H ' } },
          'encoding',
          'filetype'
        },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { {
          'filename',
          file_status = true, -- displays file status (readonly status, modified status)
          path = 1 -- 0 = just filename, 1 = relative path, 2 = absolute path
        } },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {}
      },
      tabline = {},
      extensions = { 'fugitive' }
    },
  }
}
