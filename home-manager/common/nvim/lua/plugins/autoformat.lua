return { -- Autoformat
	"stevearc/conform.nvim",
	event = "VeryLazy",
	opts = {
		notify_on_error = false,
		format_on_save = {
			timeout = 500,
			lsp_format = "fallback",
		},
		formatters_by_ft = {
			lua = { "stylua" },
			-- Conform can also run multiple formatters sequentially
			-- python = { "isort", "black" },
			--
			-- You can use a sub-list to tell conform to run *until* a formatter
			-- is found.
			-- javascript = { { "prettierd", "prettier" } },
			go = { "gofmt", stop_after_first = true },
			-- templ = { "templ" },
			yaml = { "yq" },
			json = { "jq" },
			swift = { "swiftformat" },
			nix = { "alejandra" },
			["*"] = { "trim_newlines", "trim_whitespace" },
		},
	},
}
