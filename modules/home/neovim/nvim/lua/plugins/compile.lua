return {
	"ej-shafran/compile-mode.nvim",
	-- tag = "v5.*",
	-- you can just use the latest version:
	branch = "latest",
	-- or the most up-to-date updates:
	-- branch = "nightly",
	dependencies = {
		"nvim-lua/plenary.nvim",
		-- if you want to enable coloring of ANSI escape codes in
		-- compilation output, add:
		{ "m00qek/baleia.nvim", tag = "v1.4.0" },
	},
	event = "VeryLazy",
	keys = {
        { "m<space>", ":Make " },
        { "m<cr>",    "<cmd>Make<cr>" },
	},
	config = function()
		---@type CompileModeOpts
		vim.g.compile_mode = {
		-- to add ANSI escape code support, add:
			baleia_setup = true,
			default_command = "",
		}

		vim.keymap.set("n", "c<space>", vim.cmd.Compile)
	end,
}
