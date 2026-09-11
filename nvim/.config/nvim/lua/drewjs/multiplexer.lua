-- Seamless window navigation across nvim splits and the outer multiplexer
-- (herdr or tmux). Replaces alexghergh/nvim-tmux-navigation, which only knew
-- about tmux.
--
-- tmux did the equivalent check shell-side with an `is_vim` ps grep (see
-- tmux/.config/tmux/tmux.conf). herdr has no such hook, so the check lives
-- here instead: try to move within nvim, and only fall through to the
-- multiplexer when nvim had nowhere to go.

local M = {}

local wincmd = { left = "h", down = "j", up = "k", right = "l" }
local tmux_flag = { left = "-L", down = "-D", up = "-U", right = "-R" }

local function focus_outer(dir)
	if vim.env.HERDR_ENV == "1" then
		-- --current resolves via the HERDR_PANE_ID herdr injects into the pane.
		vim.system({ "herdr", "pane", "focus", "--direction", dir, "--current" })
	elseif vim.env.TMUX then
		vim.system({ "tmux", "select-pane", tmux_flag[dir] })
	end
end

function M.navigate(dir)
	local from = vim.api.nvim_get_current_win()
	vim.cmd.wincmd(wincmd[dir])
	if vim.api.nvim_get_current_win() == from then
		focus_outer(dir)
	end
end

-- tmux: bind -r f run-shell "tmux neww ~/.local/bin/tmux-sessionizer"
function M.sessionizer()
	if vim.env.HERDR_ENV == "1" then
		-- --spawn gives it a tty of its own; nvim has none to lend.
		vim.system({ "herdr-sessionizer", "--spawn" })
	elseif vim.env.TMUX then
		vim.system({ "tmux", "neww", "tmux-sessionizer" })
	end
end

function M.setup()
	for dir, key in pairs(wincmd) do
		vim.keymap.set("n", "<C-" .. key .. ">", function()
			M.navigate(dir)
		end, { desc = "Navigate " .. dir .. " (nvim split or multiplexer pane)" })
	end
end

return M
