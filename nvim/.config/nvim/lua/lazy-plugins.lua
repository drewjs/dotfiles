require('lazy').setup({
  'tpope/vim-sleuth',

  'tpope/vim-fugitive',

  { 'numToStr/Comment.nvim', opts = {} },

  require 'drewjs/plugins/cmp',

  require 'drewjs/plugins/conform',

  require 'drewjs/plugins/gitsigns',

  require 'drewjs/plugins/harpoon',

  require 'drewjs/plugins/lint',

  require 'drewjs/plugins/lspconfig',

  require 'drewjs/plugins/lualine',

  require 'drewjs/plugins/rose-pine',

  require 'drewjs/plugins/telescope',

  require 'drewjs/plugins/treesitter',
})
