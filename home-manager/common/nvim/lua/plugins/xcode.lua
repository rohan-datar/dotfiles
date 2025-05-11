local progress_handle

return {
	"wojciech-kulik/xcodebuild.nvim",
	enabled = false,
	dependencies = {
		"nvim-telescope/telescope.nvim",
		"MunifTanjim/nui.nvim",
		"folke/trouble.nvim",
		"j-hui/fidget.nvim",
	},
	config = function()
		require("xcodebuild").setup({
			code_coverage = {
				enabled = true,
			},
			show_build_progress_bar = false,
			logs = {
				notify = function(message, severity)
					local fidget = require("fidget")
					if progress_handle then
						progress_handle.message = message
						if not message:find("Loading") then
							progress_handle:finish()
							progress_handle = nil
							if vim.trim(message) ~= "" then
								fidget.notify(message, severity)
							end
						end
					else
						fidget.notify(message, severity)
					end
				end,
				notify_progress = function(message)
					local progress = require("fidget.progress")

					if progress_handle then
						progress_handle.title = ""
						progress_handle.message = message
					else
						progress_handle = progress.handle.create({
							message = message,
							lsp_client = { name = "xcodebuild.nvim" },
						})
					end
				end,
			},
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = { "XcodebuildBuildFinished", "XcodebuildTestsFinished" },
			callback = function(event)
				if event.data.cancelled then
					return
				end

				if event.data.success then
					require("trouble").close()
				elseif not event.data.failedCount or event.data.failedCount > 0 then
					if next(vim.fn.getqflist()) then
						require("trouble").open("quickfix")
					else
						require("trouble").close()
					end

					require("trouble").refresh()
				end
			end,
		})

		vim.keymap.set("n", "<leader>xl", "<cmd>XcodebuildToggleLogs<cr>", { desc = "Toggle Xcodebuild Logs" })
		vim.keymap.set("n", "<leader>xb", "<cmd>XcodebuildBuild<cr>", { desc = "Build Project" })
		vim.keymap.set("n", "<leader>xr", "<cmd>XcodebuildBuildRun<cr>", { desc = "Build & Run Project" })
		vim.keymap.set("n", "<leader>xt", "<cmd>XcodebuildTest<cr>", { desc = "Run Tests" })
		vim.keymap.set("n", "<leader>xT", "<cmd>XcodebuildTestClass<cr>", { desc = "Run This Test Class" })
		vim.keymap.set("n", "<leader>X", "<cmd>XcodebuildPicker<cr>", { desc = "Show All Xcodebuild Actions" })
		vim.keymap.set("n", "<leader>xd", "<cmd>XcodebuildSelectDevice<cr>", { desc = "Select Device" })
		vim.keymap.set("n", "<leader>xp", "<cmd>XcodebuildSelectTestPlan<cr>", { desc = "Select Test Plan" })
		vim.keymap.set("n", "<leader>xc", "<cmd>XcodebuildToggleCodeCoverage<cr>", { desc = "Toggle Code Coverage" })
		vim.keymap.set(
			"n",
			"<leader>xC",
			"<cmd>XcodebuildShowCodeCoverageReport<cr>",
			{ desc = "Show Code Coverage Report" }
		)
		vim.keymap.set("n", "<leader>xq", "<cmd>Telescope quickfix<cr>", { desc = "Show QuickFix List" })
	end,
}
