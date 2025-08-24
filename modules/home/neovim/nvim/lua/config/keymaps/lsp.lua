-- Rename the variable under your cursor.
--  Most Language Servers support renaming across files, etc.
vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "[R]e[n]ame" })

-- Execute a code action, usually your cursor needs to be on top of an error
-- or a suggestion from your LSP for this to activate.
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "[C]ode [A]ction" })

vim.keymap.set("n", "<leader>cl", vim.lsp.codelens.run, { desc = "[C]ode[L]ens" })

vim.keymap.set("n", "<leader>k", function()
	vim.lsp.buf.code_action({
		filter = function(c)
			return c.kind == "source.doc"
		end,
		apply = true,
	})
end, { desc = "open source documentation" })

-- Opens a popup that displays documentation about the word under your cursor
--  See `:help K` for why this keymap.
vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" })
