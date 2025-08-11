return {
	{ "tpope/vim-sleuth" }, -- Detect tabstop and shiftwidth automatically
	{ "tpope/vim-surround", event = "VeryLazy" },
	{ "tpope/vim-repeat", event = "VeryLazy" },
	{ "tpope/vim-dadbod", event = "VeryLazy" },
	{ "github/copilot.vim" },
	{
		"nvimdev/hlsearch.nvim",
		event = "BufRead",
		opts = {},
	},
}
