return {
	"stevearc/oil.nvim",
	-- Optional dependencies
	dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
	event = "VeryLazy",
	opts = {
		columns = {
			"permissions",
			"size",
			"icon",
		},
		view_options = {
			show_hidden = true,
		},
	},
}
