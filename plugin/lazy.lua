---opencode.nvim lazy integration: keybindings and server config.
local M = {}

function M.init()
	-- Remote opencode URL (skips local discovery)
	vim.g.opencode_opts = vim.g.opencode_opts or {}
	vim.g.opencode_opts.server = vim.tbl_deep_extend("force", vim.g.opencode_opts.server or {}, {
		url = "http://127.0.0.1:18789",
		username = "opencode",
		password = "opencode",
	})

	-- Keybindings
	vim.keymap.set("n", "<leader>ac", function()
		require("opencode").toggle()
	end, { desc = "Toggle OpenCode" })

	-- which-key group
	local wk_ok, wk = pcall(require, "which-key")
	if wk_ok then
		wk.add({
			{ "<leader>a", mode = { "n" }, group = "OpenCode" },
		})
	end
end

M.init()
return M
