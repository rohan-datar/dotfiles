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

-- Notification history using Snacks.win + fidget
local notification_history = function()
	-- create a bottom split via Snacks.win
	local Win = (rawget(_G, "Snacks") and Snacks.win) or require("snacks.win")
	local win = Win({
		style = "split", -- use a split instead of a float
		relative = "editor", -- split relative to the full editor
		position = "bottom", -- bottom split (like your NUI config)
		height = 0.25, -- 25% of the editor height
		border = "single",
		title = "Notifications",
		ft = "fidget_history", -- nice-to-have filetype tag
		fixbuf = true, -- keep this buffer pinned in the split
		keys = {
			q = { "close", mode = "n", desc = "Close" }, -- Snacks action
			["<Esc>"] = { "close", mode = "n" },
			["g?"] = { "toggle_help", mode = "n", desc = "Help" },
		},
		wo = { -- window options
			wrap = false,
			cursorline = false,
			spell = false,
		},
		bo = { -- buffer options
			buftype = "nofile",
			bufhidden = "wipe",
			swapfile = false,
		},
	})

	win:show() -- open the split

	-- pull history from fidget
	-- (fidget exposes history helpers like show_history/clear_history/get_history)
	-- see: doc/fidget-api.txt and issues mentioning show_history()
	local notifications = require("fidget.notification").get_history() or {}

	local buf = win.buf
	local ns = vim.api.nvim_create_namespace("FidgetHistory")
	local lines = {}
	local hl = {} -- collect {row, group, col_start, col_end}

	local row = 0
	for _, item in ipairs(notifications) do
		local date = vim.fn.strftime("%c", item.last_updated)
		local group = (item.group_name and #item.group_name > 0) and item.group_name or nil
		local annote = (item.annote and #item.annote > 0) and item.annote or nil
		local is_multi = item.message and item.message:find("\n") ~= nil

		-- build the header line
		local parts = { date }
		if group then
			table.insert(parts, group)
		end
		if annote then
			table.insert(parts, "|")
			table.insert(parts, annote)
		end
		if not is_multi and item.message and #item.message > 0 then
			table.insert(parts, item.message)
		end
		local header = table.concat(parts, " ")

		table.insert(lines, header)

		-- highlights on the header
		local col = 0
		table.insert(hl, { row, "Comment", col, col + #date })
		col = col + #date
		if group then
			col = col + 1
			table.insert(hl, { row, "Special", col, col + #group })
			col = col + #group
		end
		if annote then
			col = col + 1 -- space before '|'
			table.insert(hl, { row, "Comment", col, col + 1 })
			col = col + 2 -- '|' and following space
			table.insert(hl, { row, item.style or "Normal", col, col + #annote })
			col = col + #annote
		end
		if not is_multi and item.message and #item.message > 0 then
			col = col + 1
			table.insert(hl, { row, "Special", col, col + #item.message })
		end

		row = row + 1

		-- multiline body
		if is_multi then
			for _, m in ipairs(vim.split(item.message, "\n", { plain = true })) do
				table.insert(lines, "\t" .. m)
				row = row + 1
			end
		end
	end

	-- write lines and apply highlights
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	for _, h in ipairs(hl) do
		vim.api.nvim_buf_add_highlight(buf, ns, h[2], h[1], h[3], h[4])
	end

	-- lock the buffer
	vim.bo[buf].modifiable = false
	vim.bo[buf].readonly = true
end
-- local notification_history = function()
-- 	local Split = require("nui.split")
-- 	local Text = require("nui.text")
-- 	local Line = require("nui.line")

-- 	local split_opts = {
-- 		relative = "editor",
-- 		position = "bottom",
-- 		size = "25%",
-- 	}

-- 	local split = Split(split_opts)
-- 	split:map("n", "q", function()
-- 		split:unmount()
-- 	end, { noremap = true })

-- 	local notifications = require("fidget.notification").get_history()
-- 	for _, item in ipairs(notifications) do
-- 		local chunks = {}

-- 		table.insert(chunks, Text(vim.fn.strftime("%c", item.last_updated), "Comment"))

-- 		if item.group_name and #item.group_name > 0 then
-- 			table.insert(chunks, Text(" ", "Normal"))
-- 			table.insert(chunks, Text(item.group_name, "Special"))
-- 		end

-- 		table.insert(chunks, Text(" | ", "Comment"))

-- 		if item.annote and #item.annote > 0 then
-- 			table.insert(chunks, Text(item.annote, item.style))
-- 		end

-- 		local is_multiline_msg = string.find(item.message, "\n") ~= nil
-- 		if not is_multiline_msg then
-- 			table.insert(chunks, Text(" ", "Normal"))
-- 			table.insert(chunks, Text(item.message, "Special"))
-- 		end

-- 		local line = Line(chunks)
-- 		line:render(split.bufnr, split.ns_id, 1, 1)

-- 		if is_multiline_msg then
-- 			for i, m in ipairs(vim.split(item.message, "\n")) do
-- 				local indent = Text("\t", "Normal")
-- 				local message_text = Text(m, "Normal")
-- 				local message_line = Line({ indent, message_text })

-- 				message_line:render(split.bufnr, split.ns_id, 1 + i, 1 + i)
-- 			end
-- 		end
-- 	end

-- 	vim.api.nvim_set_option_value("modifiable", false, { buf = split.bufnr })
-- 	vim.api.nvim_set_option_value("readonly", true, { buf = split.bufnr })

-- 	split:mount()
-- end

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
