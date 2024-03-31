local M = {
  "scalameta/nvim-metals",
  ft = { "scala", "sbt" },
  event = "BufEnter",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
}

function M.config()
  local metals_config = require("metals").bare_config()

  metals_config.settings = {
    showImplicitArguments = true,
  }
  metals_config.init_options.statusBarProvider = "on"
  metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()

  vim.keymap.set("n", "<leader>lmc", function()
    require("telescope").extensions.metals.commands()
  end)

  local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "scala", "sbt", "java" },
    callback = function()
      require("metals").initialize_or_attach(metals_config)
    end,
    group = nvim_metals_group,
  })
end

return M
