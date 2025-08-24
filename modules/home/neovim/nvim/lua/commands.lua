local picker = require("snacks.picker")

vim.api.nvim_create_user_command("Help", picker.help, {
	desc = "Snacks.picker.help",
})

vim.api.nvim_create_user_command("ManK", picker.man, {
	desc = "Snacks.picker.man",
})

vim.api.nvim_create_user_command("Colors", picker.colorschemes, {
	desc = "Snacks.picker.colorschemes",
})

vim.api.nvim_create_user_command("Commands", picker.commands, {
	desc = "Snacks.picker.commands",
})

local notification_history = function()
	local Split = require("nui.split")
	local Text = require("nui.text")
	local Line = require("nui.line")

	local split_opts = {
		relative = "editor",
		position = "bottom",
		size = "25%",
	}

	local split = Split(split_opts)
	split:map("n", "q", function()
		split:unmount()
	end, { noremap = true })

	local notifications = require("fidget.notification").get_history()
	for _, item in ipairs(notifications) do
		local chunks = {}

		table.insert(chunks, Text(vim.fn.strftime("%c", item.last_updated), "Comment"))

		if item.group_name and #item.group_name > 0 then
			table.insert(chunks, Text(" ", "Normal"))
			table.insert(chunks, Text(item.group_name, "Special"))
		end

		table.insert(chunks, Text(" | ", "Comment"))

		if item.annote and #item.annote > 0 then
			table.insert(chunks, Text(item.annote, item.style))
		end

		local is_multiline_msg = string.find(item.message, "\n") ~= nil
		if not is_multiline_msg then
			table.insert(chunks, Text(" ", "Normal"))
			table.insert(chunks, Text(item.message, "Special"))
		end

		local line = Line(chunks)
		line:render(split.bufnr, split.ns_id, 1, 1)

		if is_multiline_msg then
			for i, m in ipairs(vim.split(item.message, "\n")) do
				local indent = Text("\t", "Normal")
				local message_text = Text(m, "Normal")
				local message_line = Line({ indent, message_text })

				message_line:render(split.bufnr, split.ns_id, 1 + i, 1 + i)
			end
		end
	end

	vim.api.nvim_set_option_value("modifiable", false, { buf = split.bufnr })
	vim.api.nvim_set_option_value("readonly", true, { buf = split.bufnr })

	split:mount()
end

vim.api.nvim_create_user_command("Notifications", notification_history, {
	desc = "Fidget history",
})

vim.api.nvim_create_user_command("Make", function(params)
	-- Insert args at the '$*' in the makeprg
	local cmd, num_subs = vim.o.makeprg:gsub("%$%*", params.args)
	if num_subs == 0 then
		cmd = cmd .. " " .. params.args
	end
	require("compile-mode").compile({
		args = vim.fn.expandcmd(cmd),
	})
end, {
	desc = "Run your makeprg in compile mode",
	nargs = "*",
})

vim.api.nvim_create_autocmd("QuickFixCmdPost", {
	callback = function()
		vim.cmd([[Trouble qflist open]])
	end,
})
