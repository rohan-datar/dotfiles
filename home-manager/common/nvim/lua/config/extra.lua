-- Add custom filetypes for Java CUP and JLex
vim.filetype.add({
	extension = {
		jlex = "jflex",
		jflex = "jflex",
		cup = "cup",
		grammar = "ebnf",
		leaf = "html",
	},
})

vim.diagnostic.config({
	virtual_text = false,
	virtual_lines = {
		current_line = true,
	},
})
