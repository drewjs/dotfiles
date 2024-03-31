require('lazy').setup({
  -- detect tabstop and shiftwidth automatically
  'tpope/vim-sleuth',

  -- "gc" to comment visual regions/lines
  'numToStr/Comment.nvim',

  require 'drewjs/plugins/cmp',

  require 'drewjs/plugins/gitsigns',

  require 'drewjs/plugins/harpoon',

  require 'drewjs/plugins/rose-pine',

  require 'drewjs/plugins/telescope',

  require 'drewjs/plugins/treesitter',
})
