return {

	"tpope/vim-sleuth", -- Detect tabstop and shiftwidth automatically

	"nvim-lua/plenary.nvim",

	{ "tpope/vim-eunuch", event = "VeryLazy" },
	{ "tpope/vim-unimpaired", event = "VeryLazy" },
	{ "tpope/vim-surround", event = "VeryLazy" },
	{ "tpope/vim-repeat", event = "VeryLazy" },

	{
		"nvimdev/hlsearch.nvim",
		event = "BufRead",
		opts = {},
	},

	{
		"smilhey/ed-cmd.nvim",
		event = "VeryLazy",
		config = function()
			require("ed-cmd").setup({
				-- Those are the default options, you can just call setup({}) if you don't want to change the defaults
				cmdline = { keymaps = { edit = "<ESC>", execute = "<CR>" } },
				-- You enter normal mode in the cmdline with edit and execute a command from normal mode with execute
				pumenu = { max_items = 100 },
			})
		end,
	},
}
