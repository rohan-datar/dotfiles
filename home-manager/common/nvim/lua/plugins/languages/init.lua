return {
	{
		-- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
		-- used for completion, annotations and signatures of Neovim apis
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				-- Load luvit types when the `vim.uv` word is found
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
			},
		},
	},
	{ "Bilal2453/luvit-meta", lazy = true },
	{
		"catgoose/templ-goto-definition",
		ft = { "go" },
		config = true,
		dependenciies = "nvim-treesitter/nvim-treesitter", -- optional
		enabled = false,
	},
	{
		"fatih/vim-go",
		ft = { "go" },
		enabled = false,
	},
}
