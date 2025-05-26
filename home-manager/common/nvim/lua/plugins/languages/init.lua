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
	-- {
	-- 	"ray-x/lsp_signature.nvim",
	-- 	event = "VeryLazy",
	-- 	opts = {
	-- 		bind = true,
	-- 		padding = " ",
	-- 		handler_opts = {
	-- 			border = "rounded",
	-- 		},
	-- 	},
	-- },
	{
		"catgoose/templ-goto-definition",
		ft = { "go" },
		config = true,
		dependenciies = "nvim-treesitter/nvim-treesitter", -- optional
	},

	{
		"fatih/vim-go",
		ft = { "go" },
	},
}
