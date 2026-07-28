-- Tree-sitter parser names (not filetypes) to keep installed.
local ensure_installed = {
  "bash",
  "c",
  "css",
  "diff",
  "go",
  "gomod",
  "html",
  "javascript",
  "json",
  "lua",
  "luadoc",
  "markdown",
  "markdown_inline",
  "query",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main", -- `master` is locked and does not support nvim 0.12
    lazy = false, -- upstream: this plugin does not support lazy-loading
    build = ":TSUpdate",
    config = function()
      -- Async; individual languages are skipped when already installed.
      require("nvim-treesitter").install(ensure_installed)

      -- `main` ships no `highlight`/`indent` modules. Highlighting and
      -- indentation are wired to Neovim's built-in treesitter runtime.
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("drewjs-treesitter", { clear = true }),
        callback = function(ev)
          local lang = vim.treesitter.language.get_lang(ev.match)
          if not lang or not vim.treesitter.language.add(lang) then
            return
          end
          vim.treesitter.start(ev.buf, lang)
          -- Only where an indents.scm exists, to match the old
          -- `indent = { enable = true }` behaviour.
          if #vim.api.nvim_get_runtime_file("queries/" .. lang .. "/indents.scm", false) > 0 then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "BufReadPost",
    opts = {
      max_lines = 3,
    },
  },
}
