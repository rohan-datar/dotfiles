
-- Add custom filetypes for Java CUP and JLex
vim.filetype.add({
	extension = {
		jlex = "jflex",
		jflex = "jflex",
		cup = "cup",
		grammar = "ebnf",
	},
})

vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = {
		current_line = true,
	},
})
