# opencode.nvim

A Neovim plugin that bridges Neovim and the OpenCode AI assistant via HTTP. Connect to a local or remote OpenCode server and interact through prompts, context injection, session management, and edit review — all from within Neovim.

Located in `tools/nvim/opencode/` as part of the monorepo.

## Features

- **Ask** — prompt OpenCode with context from your buffers
- **Select** — browse prompts, commands, and actions in a picker
- **Prompt** — send a prompt to the current session
- **Command** — run registered OpenCode commands (`/explain`, `/fix`, etc.)
- **Operator** — add visual selections or ranges to a session (`go` / `goo`)
- **Events** — real-time SSE integration: buffer reload, statusline, permission requests, edit diffs
- **Remote-ready** — connect to any OpenCode HTTP endpoint (default `http://127.0.0.1:42345`)

## Requirements

- Neovim >= 0.10
- `curl` (for HTTP communication with the OpenCode server)
- OpenCode server running and accessible at the configured URL
- [snacks.nvim](https://github.com/folke/snacks.nvim) (optional, enhances `ask()` and `select()`)
- [which-key.nvim](https://github.com/folke/which-key.nvim) (optional, for keybinding hints)

## Configuration

### Server connection

The server URL is the primary config. Set it to your OpenCode HTTP endpoint:

```lua
vim.g.opencode_opts = {
  server = {
    url = "http://127.0.0.1:18789",  -- remote opencode
    -- Or leave nil to auto-discover a local service (service.json)
    username = "opencode",            -- basic auth (optional)
    password = "your-password",       -- basic auth (optional)
  },
}
```

### Keybindings

| Key | Mode | Action |
|---|---|---|
| `<leader>ao` | n, t, v | Toggle OpenCode panel |
| `<C-.>` | n, t, v | Quick toggle OpenCode |
| `<leader>aa` | n, v | Ask with context |
| `<leader>ax` | n, v | Action menu |
| `<leader>ap` | n, v | Add to session |
| `<leader>ai` | n, x | Ask |
| `<leader>aI` | n, x | Ask with context |
| `<leader>ab` | n, x | Ask about buffer |
| `<leader>ape` | n, x | Explain code |
| `<leader>apf` | n, x | Fix code |
| `<leader>apd` | n, x | Diagnose |
| `<leader>apr` | n, x | Review |
| `<leader>apt` | n, x | Generate tests |
| `<leader>apo` | n, x | Optimize |
| `go` | n, x | Add range to session |
| `goo` | n | Add line to session |
| `<S-C-u>` | n | Scroll up (half page) |
| `<S-C-d>` | n | Scroll down (half page) |

## Usage

1. Press `<leader>a` to see the OpenCode action group
2. Choose an action (ask, prompt, select, etc.)
3. The plugin connects to your configured OpenCode server and sends the prompt

## API

- `require("opencode").ask(default)` — input a prompt with context placeholders
- `require("opencode").select(opts)` — picker with prompts and commands
- `require("opencode").prompt(text)` — send a prompt directly
- `require("opencode").command(name, text)` — run a registered command
- `require("opencode").operator(prompt)` — operator for visual ranges
- `require("opencode").statusline` — statusline function
- `require("opencode").format(opts)` — format a buffer/range for OpenCode

## Events

The plugin subscribes to OpenCode's SSE stream and dispatches `OpencodeEvent:*` User autocmds:

- `OpencodeEvent:server.connected` — connected to the server
- `OpencodeEvent:session.status` — session status changed (idle/busy/retry)
- `OpencodeEvent:file.edited` — a file was edited (triggers buffer reload)
- `OpencodeEvent:permission.asked` — permission request from OpenCode
- `OpencodeEvent:permission.replied` — permission was answered
- `OpencodeEvent:global.disposed` — server disposed

## Health Check

Run `:checkhealth opencode` to verify your setup.
