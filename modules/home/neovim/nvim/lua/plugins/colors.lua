return { -- You can easily change to a different colorscheme.
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
