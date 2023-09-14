local M = {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  dependencies = {
    'windwp/nvim-ts-autotag',
  },
  event = 'BufReadPost',
}

function M.config()
  require('nvim-treesitter.configs').setup {
    ensure_installed = { 'astro', 'css', 'scss', 'html', 'json', 'markdown', 'go', 'lua', 'python', 'rust', 'scala', 'javascript', 'tsx', 'typescript', 'vimdoc', 'vim' },
    auto_install = false,
    highlight = {
      enable = true,
    },
    autotag = {
      enable = true,
    },
    context_commentstring = {
      enable = true,
    },
  }
end

return M
