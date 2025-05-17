return {
	"folke/snacks.nvim",
	-- enabled = false,
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		-- your configuration comes here
		-- or leave it empty to use the default settings
		-- refer to the configuration section below
		bigfile = { enabled = true },
		dashboard = {
			enabled = true,
			example = "files",
		},
		indent = {
			enabled = true,
			animate = { enabled = false },
		},
		scope = { enabled = true },
		quickfile = { enabled = true },
		picker = {
			sources = {
				files = { hidden = true },
				grep = { hidden = true },
				explorer = { hidden = true },
			},
			win = {
				input = {
					keys = {
						["<Tab>"] = { "list_down", mode = { "i", "n" } },
						["<S-Tab>"] = { "list_up", mode = { "i", "n" } },
						["<c-j>"] = { "select_and_next", mode = { "i", "n" } },
						["<c-k>"] = { "select_and_prev", mode = { "i", "n" } },
					},
				},
			},
			ui_select = true,
		},
	},

	keys = {
		-- General keymaps
		{
			"<leader><leader>",
			function()
				Snacks.picker.smart()
			end,
			desc = "Smart Search",
		},
		{
			"<leader>f",
			function()
				Snacks.picker.files()
			end,
			desc = "Find Files",
		},
		{
			"<leader>b",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Find Buffers",
		},
		{
			"<leader>qf",
			function()
				Snacks.picker.qflist()
			end,
			desc = "Quickfix List",
		},
		{
			"<leader>h",
			function()
				Snacks.picker.help()
			end,
			desc = "Help Pages",
		},
		{
			"<leader>mm",
			function()
				Snacks.picker.man()
			end,
			desc = "Man Pages",
		},
		{
			"<leader>gb",
			function()
				Snacks.picker.git_branches()
			end,
			desc = "Git Branches",
		},
		{
			"<leader>u",
			function()
				Snacks.picker.undo({
					layout = { preset = "sidebar", preview = true },
				})
			end,
		},

		-- Grep
		{
			"<leader>gr",
			function()
				Snacks.picker.grep()
			end,
			desc = "Grep",
		},
		{
			"<leader>gs",
			function()
				Snacks.picker.grep_word()
			end,
			desc = "Grep Word",
			mode = { "n", "x" },
		},
		{
			"<leader>/",
			function()
				Snacks.picker.lines()
			end,
			desc = "Grep in buffer",
		},

		-- LSP keymaps
		{
			"gd",
			function()
				Snacks.picker.lsp_definitions()
			end,
			desc = "Go To Definition",
		},
		{
			"gr",
			function()
				Snacks.picker.lsp_references()
			end,
			desc = "Find All References",
		},
		{
			"gi",
			function()
				Snacks.picker.lsp_implementations()
			end,
			desc = "Go To Implementation",
		},
		{
			"gD",
			function()
				Snacks.picker.lsp_type_definitions()
			end,
			desc = "Go To Type Definition",
		},
		{
			"<leader>ss",
			function()
				Snacks.picker.lsp_symbols()
			end,
			desc = "LSP Symbols",
		},
	},
}
