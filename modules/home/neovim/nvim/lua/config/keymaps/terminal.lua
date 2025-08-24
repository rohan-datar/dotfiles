local autocmd = vim.api.nvim_create_autocmd

local create_terminal_buffer = function(vertical)
	local cmd = "split"
	if vertical then
		cmd = "vsplit"
	end

	vim.cmd({ cmd = cmd, args = { "term://$SHELL --login" } })
	autocmd("TermClose", {
		buffer = 0,
		callback = function(args)
			vim.cmd({ cmd = "bdelete", args = { args.buf }, bang = true })
		end,
	})
end

vim.keymap.set("n", "<leader>tt", function()
	create_terminal_buffer(false)
end)

vim.keymap.set("n", "<leader>TT", function()
	create_terminal_buffer(true)
end)

vim.keymap.set("t", "<C-w><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
vim.keymap.set("t", "<C-w>:", "<C-\\><C-n>:", { desc = "Enter command mode" })
vim.keymap.set("t", "<C-q>:", vim.cmd.quit, { desc = "Quit terminal mode" })
vim.keymap.set("t", "<C-w>_", function()
	vim.cmd.wincmd("_")
end)
vim.keymap.set("t", "<C-w>=", function()
	vim.cmd.wincmd("=")
end)

vim.keymap.set({ "n", "t" }, "<leader>tf", function()
	local term_bufs = vim.tbl_filter(function(bufnr)
		return vim.api.nvim_buf_is_loaded(bufnr) and string.find(vim.api.nvim_buf_get_name(bufnr), "term://.*") ~= nil
	end, vim.api.nvim_list_bufs())

	num_bufs = #term_bufs

	if num_bufs == 0 then
		create_terminal_buffer(false)

		return
	elseif num_bufs == 1 then
		vim.cmd.split()
		vim.cmd.buffer(term_bufs[1])

		return
	end

	vim.ui.select(term_bufs, {
		prompt = "Select terminal to open",
		format_item = function(item)
			return string.format("%d: %s", item, vim.api.nvim_buf_get_var(item, "term_title"))
		end,
	}, function(choice)
		if choice == nil then
			return
		end

		vim.cmd.split()
		vim.cmd.buffer(choice)
	end)
end)

local termgroup = vim.api.nvim_create_augroup("termgroup", { clear = true })
autocmd({ "BufEnter", "TermOpen" }, {
	group = termgroup,
	pattern = "term://*",
	command = "startinsert",
})

autocmd("TermOpen", {
	group = termgroup,
	pattern = "*",
	callback = function()
		vim.opt_local.spell = false
		vim.opt_local.number = false
		vim.opt_local.signcolumn = "no"
		vim.keymap.set("n", "q", vim.cmd.startinsert, { buffer = true })
	end,
})
