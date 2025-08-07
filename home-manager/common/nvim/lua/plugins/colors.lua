return { -- You can easily change to a different colorscheme.
	-- Change the name of the colorscheme plugin below, and then
	-- change the command in the config to whatever the name of that colorscheme is.
	--
	-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
	-- "folke/tokyonight.nvim",
	-- priority = 1000,                 -- Make sure to load this before all the other start plugins.
	-- config = function()
	--     local transparent = true     -- set to true if you would like to enable transparency
	--     require("tokyonight").setup({
	--         style = "night",
	--         transparent = transparent,
	--         styles = {
	--             sidebars = transparent,
	--             floats = transparent,
	--         },
	--     })

	--     vim.cmd("colorscheme tokyonight")
	-- end,
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				flavor = "mocha",
				transparent_background = true,
				show_end_of_buffer = true,
				float = {
					transparent = true,
				},
			})

			vim.cmd("colorscheme catppuccin")
		end,
	},
}
