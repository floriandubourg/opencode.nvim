# opencode.nvim

A Neovim plugin that toggles a remote OpenCode instance in a right-side terminal pane.

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

**`lazy = false` is required.** This plugin installs keymaps through `plugin/` files, which Neovim auto-loads at startup. If lazy.nvim defers loading the plugin, the keymap never appears.

### From source (monorepo)

```lua
{
  dir = "/path/to/tools/nvim/opencode",
  lazy = false,
  dependencies = { "folke/snacks.nvim", "folke/which-key.nvim" },
  opts = {},
}
```

## Requirements

- **Neovim >= 0.10**
- **OpenCode server** — running at `http://127.0.0.1:18789`
- **snacks.nvim** (hard dependency) — provides `snacks.terminal` for the pane
- **which-key.nvim** (hard dependency) — labels the `<leader>a` menu

## Keybindings

| Key | Mode | Action |
|---|---|---|
| `<leader>ao` | n | Toggle OpenCode pane |

## Usage

1. Press `<leader>a` to see the OpenCode group (labelled by which-key)
2. Press `<leader>ao` to open/close the OpenCode terminal pane

The pane runs `OPENCODE_PASSWORD=opencode opencode --server http://127.0.0.1:18789` in a right-side panel (35% width) with working directory `/build`.

## Layout

```
lua/opencode/
└── opencode.lua      main entry: toggle()
plugin/
└── lazy.lua          keymaps, which-key, server defaults (auto-loaded at startup)
```
