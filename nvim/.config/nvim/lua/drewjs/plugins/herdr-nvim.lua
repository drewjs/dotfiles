-- Code annotations sent to the agent in the herdr pane next door: comment lines
-- like a code review, then push them all across with file:line and git context.
--
-- The herdr half of this plugin (the sidebar and file picker) is a herdr plugin,
-- installed from the same repo — see herdr-plugins/ in the dotfiles root.
--
-- Keymaps are the plugin's own defaults under <leader>a. Harpoon's <leader>a add
-- still fires, after timeoutlen (300ms).
--
-- Pinned to the same tag the herdr half is pinned to: the two halves ship from
-- one repo and talk to each other, so they move together or not at all.
return {
	{
		"ChmaraX/herdr-nvim",
		tag = "v1.0.0",
		event = "VeryLazy",
		opts = {},
	},
}
