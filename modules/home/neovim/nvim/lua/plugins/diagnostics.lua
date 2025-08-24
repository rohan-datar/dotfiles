return {
	"folke/trouble.nvim",
	event = "VeryLazy",
	cmd = "Trouble",
	specs = {
		"folke/snacks.nvim",
		opts = function(_, opts)
			return vim.tbl_deep_extend("force", opts or {}, {
				picker = {
					actions = require("trouble.sources.snacks").actions,
					win = {
						input = {
							keys = {
								["<c-t>"] = {
									"trouble_open",
									mode = { "n", "i" },
								},
								["<c-a>"] = {
									"trouble_add",
									mode = { "n", "i" },
								},
							},
						},
					},
				},
			})
		end,
	},
	opts = {
		focus = true,
	},
	keys = {
		{
			"<leader>e",
			"<cmd>Trouble diagnostics toggle<cr>",
			desc = "Diagnostics (Trouble)",
		},
	},
}
