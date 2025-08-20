return {
	{
		"github/copilot.vim",
		cmd = "Copilot",
		event = "BufWinEnter",
		init = function()
			vim.g.copilot_no_maps = true
		end,
		config = function()
			-- Block the normal Copilot suggestions
			vim.api.nvim_create_augroup("github_copilot", { clear = true })
			vim.api.nvim_create_autocmd({ "FileType", "BufUnload" }, {
				group = "github_copilot",
				callback = function(args)
					vim.fn["copilot#On" .. args.event]()
				end,
			})
			vim.fn["copilot#OnFileType"]()
		end,
	},
	{
		"saghen/blink.cmp",

		lazy = false, -- lazy loading handled internally
		-- optional: provides snippets for the snippet source
		dependencies = {
			{ "fang2hou/blink-copilot" },
			{
				"L3MON4D3/LuaSnip",
				version = "v2.*",
				build = (function()
					-- Build Step is needed for regex support in snippets.
					-- This step is not supported in many windows environments.
					-- Remove the below condition to re-enable on windows.
					if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
						return
					end
					return "make install_jsregexp"
				end)(),
				dependencies = {
					-- `friendly-snippets` contains a variety of premade snippets.
					--    See the README about individual language/framework/plugin snippets:
					--    https://github.com/rafamadriz/friendly-snippets
					{
						"rafamadriz/friendly-snippets",
						config = function()
							require("luasnip.loaders.from_vscode").lazy_load()
						end,
					},
				},
			},
		},
		-- use a release tag to download pre-built binaries
		-- version = "v0.*",
		-- If you use nix, you can build from source using latest nightly rust with:
		build = "nix run .#build-plugin",

		---@module 'blink.cmp'
		---@type blink.cmp.Config
		opts = {
			-- 'default' for mappings similar to built-in completion
			-- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
			-- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
			-- see the "default configuration" section below for full documentation on how to define
			-- your own keymap.
			keymap = {
				preset = "none",
				["<Tab>"] = {
					function(cmp)
						if cmp.is_visible then
							return cmp.select_next()
						end
						if cmp.snippet_active() then
							return cmp.snippet_forward()
						end
						return false
					end,
					"fallback",
				},
				["<S-Tab>"] = {
					function(cmp)
						if cmp.is_visible then
							return cmp.select_prev()
						end
						if cmp.snippet_active() then
							return cmp.snippet_backward()
						end
						return false
					end,
					"fallback",
				},
				["<CR>"] = { "accept", "fallback" },
				["<C-space>"] = { "show", "show_documentation", "hide_documentation", "fallback" },
				["<C-e>"] = { "hide", "cancel", "fallback" },

				["<C-u>"] = { "scroll_documentation_up", "fallback" },
				["<C-d>"] = { "scroll_documentation_down", "fallback" },
			},
			appearance = {
				-- Sets the fallback highlight groups to nvim-cmp's highlight groups
				-- Useful for when your theme doesn't support blink.cmp
				-- will be removed in a future release
				use_nvim_cmp_as_default = true,
				-- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
				-- Adjusts spacing to ensure icons are aligned
				nerd_font_variant = "mono",
			},

			snippets = {
				expand = function(snippet)
					require("luasnip").lsp_expand(snippet)
				end,
				active = function(filter)
					if filter and filter.direction then
						return require("luasnip").jumpable(filter.direction)
					end
					return require("luasnip").in_snippet()
				end,
				jump = function(direction)
					require("luasnip").jump(direction)
				end,
			},
			-- default list of enabled providers defined so that you can extend it
			-- elsewhere in your config, without redefining it, via `opts_extend`
			sources = {
				default = { "lsp", "path", "snippets", "buffer", "copilot" },
				-- optionally disable cmdline completions
				-- cmdline = {},
				providers = {
					copilot = {
						name = "copilot",
						module = "blink-copilot",
						score_offset = 100,
						async = true,
					},
				},
			},

			-- experimental signature help support
			signature = { enabled = true },
			completion = {
				trigger = { show_in_snippet = false },
				list = {
					selection = {
						preselect = false,
						auto_insert = true,
					},
				},

				menu = {
					draw = {
						columns = { { "label", "label_description", gap = 3 }, { "kind_icon", "kind" } },
					},
				},
			},
		},
		-- allows extending the providers array elsewhere in your config
		-- without having to redefine it
		opts_extend = { "sources.default" },
	},
}
