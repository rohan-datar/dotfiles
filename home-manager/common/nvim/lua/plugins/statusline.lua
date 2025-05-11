return {
	"nvim-lualine/lualine.nvim",
	event = "VeryLazy",
	config = function()
		local function diff_source()
			local gitsigns = vim.b.gitsigns_status_dict
			if gitsigns then
				return {
					added = gitsigns.added,
					modified = gitsigns.changed,
					removed = gitsigns.removed,
				}
			end
		end
		local symbols = require("trouble").statusline({
			mode = "lsp_document_symbols",
			groups = {},
			title = false,
			filter = { range = true },
			format = "{kind_icon}{symbol.name:Normal}",
			-- The following line is needed to fix the background color
			-- Set it to the lualine section you want to use
			hl_group = "lualine_c_normal",
		})

		local fugitive = {
			sections = {
				lualine_a = { "FugitiveHead" },
				lualine_z = { "location" },
			},
			filetypes = { "fugitive" },
		}

		require("lualine").setup({
			options = {
				icons_enabled = true,
				component_separators = { left = "", right = "" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_b = {
					"branch",
					{ "diff", source = diff_source },
					"diagnostics",
				},
				lualine_c = {
					{
						symbols.get,
						cond = symbols.has,
					},
				},
				lualine_x = {
					{ "filename", path = 1 },
				},
				lualine_y = {
					"encoding",
					"filetype",
				},
				lualine_z = {
					"progress",
					"location",
				},
			},
			extensions = {
				fugitive,
				"quickfix",
				"trouble",
				"oil",
			},
		})
	end,
}
