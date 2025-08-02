return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp",
			-- "nvim-java/nvim-java",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities =
				vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities(capabilities))
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}

			-- clangd = {},
			lspconfig.gopls.setup({
				capabilities = capabilities,
				settings = {
					gopls = {
						gofumpt = true,
						linksInHover = "gopls",
					},
				},
			})

			lspconfig.lua_ls.setup({
				capabilities = capabilities,
				on_init = function(client)
					if client.workspace_folders then
						local path = client.workspace_folders[1].name
						if vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc") then
							return
						end
					end

					client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
						runtime = {
							-- Tell the language server which version of Lua you're using
							-- (most likely LuaJIT in the case of Neovim)
							version = "LuaJIT",
						},
						-- Make the server aware of Neovim runtime files
						workspace = {
							checkThirdParty = false,
							library = {
								vim.env.VIMRUNTIME,
								-- Depending on the usage, you might want to add additional paths here.
								-- "${3rd}/luv/library"
								-- "${3rd}/busted/library",
							},
							-- or pull in all of 'runtimepath'. NOTE: this is a lot slower and will cause issues when working on your own configuration (see https://github.com/neovim/nvim-lspconfig/issues/3189)
							-- library = vim.api.nvim_get_runtime_file("", true)
						},
					})
				end,
				settings = {
					Lua = {
						completion = {
							callSnippet = "Replace",
						},
						-- You can toggle below to ignore Lua_LS's noisy `missing-fields` warnings
						diagnostics = {
							disable = { "missing-fields" },
							globals = { "vim" },
						},
					},
				},
			})

			lspconfig.jedi_language_server.setup({ capabilities = capabilities })
			lspconfig.templ.setup({ capabilities = capabilities })
			lspconfig.html.setup({ capabilities = capabilities })
			lspconfig.htmx.setup({ capabilities = capabilities })
			lspconfig.yamlls.setup({ capabilities = capabilities })
			lspconfig.jdtls.setup({ capabilities = capabilities })

			lspconfig.markdown_oxide.setup({
				capabilities = {
					workspace = {
						didChangeWatchedFiles = {
							dynamicRegistration = true,
						},
					},
				},
				on_attach = function(client, bufnr)
					local function check_codelens_support()
						local clients = vim.lsp.get_clients({ bufnr = 0 })
						for _, c in ipairs(clients) do
							if c.server_capabilities.codeLensProvider then
								return true
							end
						end
						return false
					end

					vim.api.nvim_create_autocmd(
						{ "TextChanged", "InsertLeave", "CursorHold", "LspAttach", "BufEnter" },
						{
							buffer = bufnr,
							callback = function()
								if check_codelens_support() then
									vim.lsp.codelens.refresh({ bufnr = 0 })
								end
							end,
						}
					)
					-- trigger codelens refresh
					vim.api.nvim_exec_autocmds("User", { pattern = "LspAttached" })

					-- setup Markdown Oxide daily note commands
					if client.name == "markdown_oxide" then
						vim.api.nvim_create_user_command("Daily", function(args)
							local input = args.args

							vim.lsp.buf.execute_command({ command = "jump", arguments = { input } })
						end, { desc = "Open daily note", nargs = "*" })
					end
				end,
			})

			lspconfig.zls.setup({})

			lspconfig.sourcekit.setup({
				capabilities = {
					workspace = {
						didChangeWatchedFiles = {
							dynamicRegistration = true,
						},
					},
				},
			})

			lspconfig.sqls.setup({})
		end,
	},
}
