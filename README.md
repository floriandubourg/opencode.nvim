# opencode.nvim

A Neovim plugin that bridges Neovim and the OpenCode AI assistant via HTTP. Connect to a local or remote OpenCode server and interact through prompts, context injection, session management, and edit review — all from within Neovim.

## Install

### lazy.nvim (LazyVim / Rime)

```lua
{
  "floriandubourg/opencode.nvim",
  lazy = false,
  dependencies = { "folke/snacks.nvim", "folke/which-key.nvim" },
  opts = {},
}
```

**`lazy = false` is required.** This plugin installs keymaps and server configuration through `plugin/` files, which Neovim auto-loads at startup. If lazy.nvim defers loading the plugin, those `plugin/` files never fire, and no keymaps or server setup ever appear.

### From source (monorepo)

```lua
{
  dir = "/path/to/tools/nvim/opencode",
  lazy = false,
  dependencies = { "folke/snacks.nvim", "folke/which-key.nvim" },
  opts = {},
}
```

`dir` points to the plugin's own root — the directory that holds `lua/opencode.lua`. It is *not* `tools/nvim/lua/opencode`; lazy.nvim puts `dir` on `runtimepath` and looks for the module under `dir .. "/lua"`, so a `dir` one level too deep has no `lua/` under it at all.

### Git subtree (dedicated repo)

The plugin is published to [floriandubourg/opencode.nvim](https://github.com/floriandubourg/opencode.nvim) via `git subtree push`. To publish from this repository:

```
git subtree push --prefix tools/nvim/opencode origin opencode.nvim
```

This pushes the contents of `tools/nvim/opencode/` as the root of the `opencode.nvim` branch on `origin`. The published repository is the one consumers install with `"nickjvandyke/opencode.nvim"`.

## Requirements

- **Neovim >= 0.10**
- **curl** — used for all HTTP communication with the OpenCode server
- **OpenCode server** — running locally or accessible at the configured URL (default `http://127.0.0.1:18789`)
- **snacks.nvim** (hard dependency) — provides `snacks.input` for `ask()`, `snacks.picker` for `select()`, `snacks.terminal` for the toggle panel, and `snacks.notifier` for error messages
- **which-key.nvim** (hard dependency) — labels the `<leader>a` menu

The plugin checks for both at startup and notifies you if either is missing.

## Configuration

Configuration is passed via `vim.g.opencode_opts`. The plugin merges it with defaults on load:

```lua
vim.g.opencode_opts = {
  server = {
    url = "http://127.0.0.1:18789",  -- always 18789; skips local discovery
    username = "opencode",            -- basic auth (optional)
    password = nil,                   -- basic auth (optional)
    connect = true,                   -- connect immediately on first use
    -- start() is called when no server is found and no URL is configured.
    -- It opens a terminal with `opencode` so the user can interact with the TUI.
    -- Override with a custom function or set to false to disable auto-start.
  },
  contexts = {
    -- These are the placeholders available in prompts. Each maps to a
    -- function that returns the context text. Override or extend freely.
    ["@this"]      = require("opencode.context.builtins").this,
    ["@buffer"]    = require("opencode.context.builtins").buffer,
    ["@buffers"]   = require("opencode.context.builtins").buffers,
    ["@diagnostics"] = require("opencode.context.builtins").diagnostics,
    ["@marks"]     = require("opencode.context.builtins").marks,
    ["@quickfix"]  = require("opencode.context.builtins").quickfix,
    ["@visible"]   = require("opencode.context.builtins").visible_text,
  },
  ask = {
    prompt = "Ask OpenCode: ",
    -- snacks.input options (see snacks.nvim docs for full list)
    snacks = {
      icon = "󰚩 ",
      win = {
        title_pos = "left",
        relative = "cursor",
        row = -3,
        col = 0,
        keys = {
          i_cr = { desc = "submit" },
        },
        b = { completion = true },
        bo = { filetype = "opencode_ask" },
        on_buf = function(win)
          -- LSP completion for context placeholders
          vim.lsp.start(require("opencode.ui.ask.cmp"), { bufnr = win.buf })
        end,
      },
    },
  },
  select = {
    prompt = "OpenCode: ",
    prompts = {
      ask = "...",
      diagnostics = "Explain @diagnostics",
      document = "Add comments documenting @this",
      explain = "Explain @this and its context",
      fix = "Fix @diagnostics",
      implement = "Implement @this",
      optimize = "Optimize @this for performance and readability",
      review = "Review @this for correctness and readability",
      test = "Add tests for @this",
    },
    snacks = {
      preview = "preview",
      layout = {
        preset = "vscode",
        hidden = {}, -- preview is hidden by default
      },
    },
  },
  events = {
    enabled = true, -- subscribe to OpenCode's SSE stream
    reload = {
      enabled = true, -- auto-reload buffers edited by OpenCode (sets autoread)
    },
    permissions = {
      enabled = true, -- show permission request dialogs
      edits = {
        enabled = true, -- show diff previews for edit permissions
      },
    },
  },
}
```

### Server discovery order

When no `url` is configured, the plugin finds a server in this order:

1. The currently connected server (if already connected)
2. The configured `url` in `vim.g.opencode_opts.server.url`
3. Background services registered in OpenCode's state directory (`service.json` or `service-<channel>.json`), newest first
4. Calling `vim.g.opencode_opts.server.start()` and polling for five seconds

A configured `url` is authoritative — if it fails, the plugin does not fall back to start or polling.

## Keybindings

| Key | Mode | Action |
|---|---|---|
| `<leader>ao` | n, t, v | Toggle OpenCode panel |
| `<C-.>` | n, t, v | Quick toggle OpenCode |
| `<leader>aa` | n, v | Ask (with `@this` context) |
| `<leader>ax` | n, v | Action menu (picker) |
| `<leader>ap` | n, v | Add to session |
| `<leader>ai` | n, x | Ask (empty prompt) |
| `<leader>aI` | n, x | Ask with context (`@this`) |
| `<leader>ab` | n, x | Ask about buffer (`@file`) |
| `<leader>ape` | n, x | Explain code |
| `<leader>apf` | n, x | Fix code |
| `<leader>apd` | n, x | Diagnose |
| `<leader>apr` | n, x | Review |
| `<leader>apt` | n, x | Generate tests |
| `<leader>apo` | n, x | Optimize |
| `go` | n, x | Add range to session (operator) |
| `goo` | n | Add line to session (operator) |
| `<S-C-u>` | n | Page up (OpenCode terminal) |
| `<S-C-d>` | n | Page down (OpenCode terminal) |

Terminal buffers (`term://*:opencode`) also get scroll bindings via which-key:

| Key | Mode | Action |
|---|---|---|
| `<C-U>` | n, t | Half scroll backward |
| `<C-D>` | n, t | Half scroll forward |
| `<C-B>` | n, t | Scroll backward |
| `<C-F>` | n, t | Scroll forward |

## Usage

1. Press `<leader>a` to see the OpenCode action group (labelled by which-key)
2. Choose an action — ask, prompt, select, or one of the built-in commands
3. The plugin discovers and connects to your OpenCode server, injects context, and sends the prompt

Context placeholders (`@this`, `@buffer`, `@diagnostics`, etc.) are highlighted and completed in the ask input. Press `<Tab>` to trigger built-in completion.

## API

All functions are available via `require("opencode")`:

| Function | Description |
|---|---|
| `ask(default?)` | Input a prompt with context placeholders. Press `<Up>` to browse recent asks. Highlights and completes `@this`, `@buffer`, etc. |
| `select(opts?)` | Picker showing prompts, commands, and actions. Supports snacks.picker preview and layout options. |
| `prompt(text)` | Send a prompt directly to the most recently updated session for the current directory. Trailing `...` opens `ask()`. |
| `command(name, text?)` | Run a registered OpenCode command (e.g. `session.half.page.up`, `explain`, `fix`). |
| `operator(prompt)` | Operator function for visual ranges. Returns `"g@"` so you can use `go` / `goo` to add ranges. |
| `statusline` | Statusline function — returns connection status text. |
| `format(opts)` | Format a buffer or range as context text for OpenCode. |

## Events

The plugin subscribes to OpenCode's SSE stream and dispatches `OpencodeEvent:*` User autocmds. Each carries `args.data.event` (the raw event) and `args.data.url` (the server URL).

| Autocmd | Handler | Description |
|---|---|---|
| `OpencodeEvent:server.connected` | OpencodeStatus | Connected to the server |
| `OpencodeEvent:session.status` | OpencodeStatus | Session status changed (idle / busy / retry) |
| `OpencodeEvent:session.execution.failed` | OpencodeStatus | Session execution failed |
| `OpencodeEvent:global.disposed` | OpencodeStatus | Server disposed globally |
| `OpencodeEvent:server.instance.disposed` | OpencodeStatus | Server instance disposed |
| `OpencodeEvent:file.edited` | OpencodeReload | A file was edited — triggers buffer reload |
| `OpencodeEvent:filesystem.changed` | OpencodeReload | Filesystem changed — triggers buffer reload |
| `OpencodeEvent:permission.asked` | OpencodePermissions | Permission request from OpenCode (handled by edits or dialog handler) |
| `OpencodeEvent:permission.replied` | OpencodeEdits | Permission was answered |

Example listener:

```lua
vim.api.nvim_create_autocmd("User", {
  pattern = "OpencodeEvent:session.status",
  callback = function(args)
    local event = args.data.event
    print("Session " .. event.data.sessionID .. " is " .. event.data.status.type)
  end,
})
```

## Health Check

Run `:checkhealth opencode` to verify your setup. It checks:

- Neovim version and git commit
- `opencode` executable availability (or remote URL configuration)
- `curl` availability
- Local service discovery status
- Current connection state
- snacks.nvim input and picker availability

## Layout

```
lua/opencode/
├── opencode.lua      main entry: ask, select, prompt, command, operator, statusline, format
├── config.lua        opts table, defaults, merge from vim.g.opencode_opts
├── health.lua        :checkhealth opencode
├── api/
│   ├── command.lua   run a registered OpenCode command
│   └── prompt.lua    send a prompt to a session
├── context/
│   ├── init.lua      Context class: buf, win, cursor, range, format
│   ├── builtins.lua  @this, @buffer, @buffers, @diagnostics, @marks, @quickfix, @visible
│   └── rendered.lua  Rendered class: plaintext, extmarks, input_highlight
├── events/
│   ├── init.lua      emit OpencodeEvent:* autocmds from SSE stream
│   ├── status.lua    statusline update and statusline() export
│   └── permissions/
│       ├── init.lua  permission request dialog
│       └── edits.lua diff preview for edit permissions
├── promise/
│   ├── init.lua      Promise type (then/catch/all/race/any/all_settled)
│   └── ui.lua        vim.ui.select and vim.ui.input wrappers
├── server/
│   ├── init.lua      Server class: connect, disconnect, curl, SSE subscription, heartbeat
│   └── discovery/
│       └── init.lua  discovery: configured URL → service.json → poll → start()
└── ui/
    ├── ask/
    │   ├── init.lua  snacks.input-based prompt input
    │   └── cmp.lua   LSP completion for context placeholders
    └── select.lua    snacks.picker-based action selection

plugin/
├── lazy.lua          keymaps, which-key entries, server defaults (auto-loaded at startup)
├── highlights.lua    highlight groups
└── events/
    ├── reload.lua    OpencodeEvent:file.edited, filesystem.changed → checktime
    ├── status.lua    OpencodeEvent:server.connected, session.status, etc.
    └── permissions/
        ├── init.lua  permission request dialog
        └── edits.lua diff preview for edit permissions
```
