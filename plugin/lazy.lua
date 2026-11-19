---opencode.nvim lazy integration: keybindings, which-key, remote server config.
local M = {}

local function opencode_toggle()
  local opts = vim.g.opencode_opts or {}
  if opts.server and opts.server.toggle then
    opts.server.toggle()
  elseif opts.server and opts.server.start then
    opts.server.start()
  else
    vim.notify("OpenCode server not configured", vim.log.levels.ERROR, { title = "opencode" })
  end
end

local function register_keys()
  local keys = {
    {
      "<leader>ao",
      opencode_toggle,
      desc = "Toggle (OpenCode)",
      mode = { "n", "t", "v" },
    },
    {
      "<C-.>",
      opencode_toggle,
      desc = "Toggle Quick (OpenCode)",
      mode = { "n", "t", "v" },
    },
    {
      "<leader>aa",
      function()
        require("opencode").ask("@this: ", { submit = true })
      end,
      desc = "Ask (OpenCode)",
      mode = { "n", "v" },
    },
    {
      "<leader>ax",
      function()
        require("opencode").select()
      end,
      desc = "Action (OpenCode)",
      mode = { "n", "v" },
    },
    {
      "<leader>ap",
      function()
        require("opencode").prompt("@this")
      end,
      desc = "Add (OpenCode)",
      mode = { "n", "v" },
    },
    {
      "<S-C-u>",
      function()
        require("opencode").command("session.half.page.up")
      end,
      desc = "Page Up (OpenCode)",
      mode = "n",
    },
    {
      "<S-C-d>",
      function()
        require("opencode").command("session.half.page.down")
      end,
      desc = "Page Down (OpenCode)",
      mode = "n",
    },
    {
      "<leader>ai",
      function()
        require("opencode").ask("", { submit = true })
      end,
      desc = "Ask (OpenCode)",
      mode = { "n", "x" },
    },
    {
      "<leader>aI",
      function()
        require("opencode").ask("@this: ", { submit = true })
      end,
      desc = "Ask with context (OpenCode)",
      mode = { "n", "x" },
    },
    {
      "<leader>ab",
      function()
        require("opencode").ask("@file: ", { submit = true })
      end,
      desc = "Ask about buffer (OpenCode)",
      mode = { "n", "x" },
    },
    {
      "<leader>ape",
      function()
        require("opencode").prompt("explain", { submit = true })
      end,
      desc = "Explain (OpenCode)",
      mode = { "n", "x" },
    },
    {
      "<leader>apf",
      function()
        require("opencode").prompt("fix", { submit = true })
      end,
      desc = "Fix (OpenCode)",
      mode = { "n", "x" },
    },
    {
      "<leader>apd",
      function()
        require("opencode").prompt("diagnose", { submit = true })
      end,
      desc = "Diagnose (OpenCode)",
      mode = { "n", "x" },
    },
    {
      "<leader>apr",
      function()
        require("opencode").prompt("review", { submit = true })
      end,
      desc = "Review (OpenCode)",
      mode = { "n", "x" },
    },
    {
      "<leader>apt",
      function()
        require("opencode").prompt("test", { submit = true })
      end,
      desc = "Test (OpenCode)",
      mode = { "n", "x" },
    },
    {
      "<leader>apo",
      function()
        require("opencode").prompt("optimize", { submit = true })
      end,
      desc = "Optimize (OpenCode)",
      mode = { "n", "x" },
    },
    {
      "go",
      function()
        return require("opencode").operator("@this ")
      end,
      expr = true,
      mode = { "n", "x" },
      desc = "Add range (OpenCode)",
    },
    {
      "goo",
      function()
        return require("opencode").operator("@this ") .. "_"
      end,
      expr = true,
      mode = { "n" },
      desc = "Add line (OpenCode)",
    },
  }

  vim.keymap.set("n", "<leader>ao", opencode_toggle, { desc = "Toggle (OpenCode)" })
  vim.keymap.set({ "n", "t", "v" }, "<C-.>", opencode_toggle, { desc = "Toggle Quick (OpenCode)" })

  for _, key in ipairs(keys) do
    local mode = type(key.mode) == "table" and key.mode or { key.mode or "n" }
    vim.keymap.set(mode, key[1], key[2], { desc = key.desc })
  end
end

local function setup_which_key()
  local wk_ok, wk = pcall(require, "which-key")
  if not wk_ok then
    return
  end

  wk.add({
    { "<leader>a", mode = { "n", "x" }, group = "OpenCode" },
    { "<leader>ap", mode = { "n", "x" }, group = "Prompt" },
  })

  -- OpenCode terminal buffer keybindings
  vim.api.nvim_create_autocmd({ "TermOpen" }, {
    group = vim.api.nvim_create_augroup("opencode_buffer", { clear = false }),
    pattern = "*:opencode*",
    desc = "Assign binds specific to OpenCode buffers",
    callback = function(event)
      local bufname = vim.api.nvim_buf_get_name(event.buf)
      if string.match(bufname, "^term:.+//%d+:opencode") then
        wk.add({
          buffer = event.buf,
          mode = { "n", "t" },
          {
            "<C-U>",
            function()
              require("opencode").command("session.half.page.up")
            end,
            desc = "Half scroll backward (OpenCode)",
          },
          {
            "<C-D>",
            function()
              require("opencode").command("session.half.page.down")
            end,
            desc = "Half scroll forward (OpenCode)",
          },
          {
            "<C-B>",
            function()
              require("opencode").command("session.page.up")
            end,
            desc = "Scroll backward (OpenCode)",
          },
          {
            "<C-F>",
            function()
              require("opencode").command("session.page.down")
            end,
            desc = "Scroll forward (OpenCode)",
          },
        })
      end
    end,
  })
end

local function setup_server()
  -- Connect to remote opencode via HTTP
  vim.g.opencode_opts = vim.g.opencode_opts or {}
  vim.g.opencode_opts.server = vim.tbl_deep_extend("force", vim.g.opencode_opts.server or {}, {
    url = vim.g.opencode_opts.server and vim.g.opencode_opts.server.url or "http://127.0.0.1:18789",
    username = "opencode",
    password = "opencode",
    -- Toggle opens a snacks.terminal connected to the remote opencode web UI
    toggle = function()
      local snacks_ok, snacks = pcall(require, "snacks")
      if not snacks_ok then
        vim.notify("snacks.nvim is required for toggle", vim.log.levels.WARN, { title = "opencode" })
        return
      end
      snacks.terminal.toggle("opencode -c", {
        win = { position = "right", width = math.floor(vim.o.columns * 0.35) },
      })
    end,
    -- start is kept as an alias to toggle for backward compatibility
    start = false,
  })
end

function M.init()
  setup_server()
  register_keys()
  setup_which_key()
end

M.init()
return M
