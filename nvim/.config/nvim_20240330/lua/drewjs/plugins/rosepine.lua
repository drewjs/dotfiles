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
        variant = 'main',
        dark_variant = 'main',
        bold_vert_split = false,
        dim_inactive_windows = false,
        extend_background_behind_borders = true,

        enable = {
            --terminal = true,
            --legacy_highlights = true,         -- Improve compatibility for previous versions of Neovim
            --migrations = true,                -- Handle deprecated options automatically
        },


        styles = {
            transparency = true,
            italic = true,
        },

        --- @usage string hex value or named color from rosepinetheme.com/palette
        groups = {
            --background = 'base',
            --background_nc = '_experimental_nc',
            --panel = 'surface',
            --panel_nc = 'base',
            --border = 'pine',
            --comment = 'muted',
            --link = 'iris',
            --punctuation = 'subtle',

            --error = 'love',
            --hint = 'iris',
            --info = 'foam',
            --warn = 'gold',

            --headings = {
            --    h1 = 'iris',
            --    h2 = 'foam',
            --    h3 = 'rose',
            --    h4 = 'gold',
            --    h5 = 'pine',
            --    h6 = 'foam',
            --}
            -- or set all headings at once
            -- headings = 'subtle'
        },

        highlight_groups = {
            --TelescopeBorder = { fg = "highlight_high", bg = "none" },
            --TelescopeNormal = { bg = "none" },
            --TelescopePromptNormal = { bg = "base" },
            --TelescopeResultsNormal = { fg = "subtle", bg = "none" },
            --TelescopeSelection = { fg = "text", bg = "base" },
            --TelescopeSelectionCaret = { fg = "rose", bg = "rose" },
        },
    })

    vim.cmd.colorscheme("rose-pine")

    local function get_color(group, attr)
        local fn = vim.fn
        return fn.synIDattr(fn.synIDtrans(fn.hlID(group)), attr)
    end

    vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = get_color("GitSignsAdd", "fg"), bg = "none" })
    vim.api.nvim_set_hl(0, "GitSignsChange", { fg = get_color("GitSignsChange", "fg"), bg = "none" })
    vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = get_color("GitSignsDelete", "fg"), bg = "none" })
    vim.api.nvim_set_hl(0, "GitSignsChangeDelete", { fg = get_color("GitSignsChangeDelete", "fg"), bg = "none" })
end

return M
