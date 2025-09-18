return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"saghen/blink.cmp",
			-- "nvim-java/nvim-java",
		},
		config = function()
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			capabilities =
				vim.tbl_deep_extend("force", capabilities, require("blink.cmp").get_lsp_capabilities(capabilities))
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}

			vim.lsp.enable("gopls")
			vim.lsp.config.gopls = {
				capabilities = capabilities,
				settings = {
					gopls = {
						gofumpt = true,
						linksInHover = "gopls",
					},
				},
			}

			vim.lsp.enable("lua_ls")
			vim.lsp.config.lua_ls = {
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
			}

			vim.lsp.enable("clangd")
			vim.lsp.config.clangd = { capabilities = capabilities }
			vim.lsp.enable("jedi_language_server")
			vim.lsp.config.jedi_language_server = { capabilities = capabilities }
			-- vim.lsp.enable("templ")
			vim.lsp.config.templ = { capabilities = capabilities }
			-- vim.lsp.enable("superhtml")
			vim.lsp.config.superhtml = { capabilities = capabilities }
			vim.lsp.enable("yamlls")
			vim.lsp.config.yamlls = { capabilities = capabilities }
			vim.lsp.enable("jdtls")
			vim.lsp.config.jdtls = { capabilities = capabilities }
			vim.lsp.enable("nil_ls")
			vim.lsp.config.nil_ls = { capabilities = capabilities }

			-- vim.lsp.enable("zls")
			vim.lsp.config.zls = {}

			vim.lsp.enable("sourcekit")
			vim.lsp.config.sourcekit = {
				capabilities = {
					workspace = {
						didChangeWatchedFiles = {
							dynamicRegistration = true,
						},
					},
				},
			}

			vim.lsp.enable("markdown_oxide")
			vim.lsp.config.markdown_oxide = {
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

							client.exec_cmd({ command = "jump", arguments = { input } })
						end, { desc = "Open daily note", nargs = "*" })
					end
				end,
			}
		end,
	},
}
