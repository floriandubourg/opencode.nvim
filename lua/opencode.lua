---opencode.nvim — toggle a remote OpenCode pane.
local M = {}

---No-op: satisfies lazy.nvim's `opts = {}` call.
function M.setup() end

---Toggle the OpenCode terminal pane.
---
---Opens `OPENCODE_PASSWORD=opencode opencode --server http://127.0.0.1:18789`
---in a right-side snacks.terminal panel (cwd: /build).
function M.toggle()
	local snacks_ok, snacks = pcall(require, "snacks")
	if not snacks_ok then
		vim.notify("snacks.nvim is required", vim.log.levels.WARN, { title = "opencode" })
		return
	end
	snacks.terminal.toggle("OPENCODE_PASSWORD=opencode opencode --server http://127.0.0.1:18789", {
		win = { position = "right", width = math.floor(vim.o.columns * 0.35) },
	})
end

return M
