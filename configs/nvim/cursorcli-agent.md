# Cursor Agent — cursorcli.nvim Setup and Shortcuts

| | |
|---|---|
| **Config file** | `~/.config/nvim/lua/plugins/cursorcli.lua` |
| **Plugin repo** | [suiramdev/cursorcli.nvim](https://github.com/suiramdev/cursorcli.nvim) |
| **CLI binary** | `agent` (PATH: `~/.local/bin/agent`) |
| **Leader key** | Space |

## Installation Summary

`cursorcli.nvim` was added via lazy.nvim and installed with Lazy sync.  
The commit is pinned in `lazy-lock.json`.

## Security Choices (intentional)

- `command = { "agent" }` — no `--yolo` / `--force`
- Quick Edit is not mapped — avoids `--print` + `--approve-mcps` risk
- Only interactive terminal mode is used

**Caution:**

- Do not run the agent in untrusted repositories (`.cursor/mcp.json`, rules)
- The CLI already has file write and shell permissions; the plugin is a thin wrapper
- Do not send selections containing sensitive code or tokens

## Shortcuts (Space = leader)

| Shortcut | Action |
|----------|--------|
| `Space + ai` | Toggle agent window |
| `Space + af` | Agent (floating window) |
| `Space + av` | Agent (vertical split) |
| `Space + ah` | Agent (horizontal split) |
| `Space + ac` | Close agent window |
| `Space + an` | New chat |
| `Space + at` | Select chat (fuzzy finder) |
| `Space + aR` | Resume last session |
| `Space + ax` | Restart (new session, same chat) |
| `Space + al` | List sessions (`agent ls`) |
| `Space + ae` | Send LSP error at cursor to agent |
| `Space + aa` | Add visual selection to agent (visual mode) |
| `Space + aA` | New session + send error (normal mode), or new session + send selection (visual mode) |

## Quick Start

1. Open Neovim in the project root
2. `Space + ai` — Opens the agent window
3. Type directly to the agent, or:
   - Select code in visual mode → `Space + aa`
   - If there is an error at the cursor → `Space + ae`

**If you prefer a split layout:**

- `Space + ah` — Horizontal split (similar to the existing `Space + tt` terminal flow)
- `Space + av` — Vertical split

## Compatibility with Current Config

| Binding | Behavior |
|---------|----------|
| `Space + Enter` | Terminal/editor pane toggle (`vim-options.lua`) — not the agent |
| `Space + l` | Still moves to the right pane (`vim-options.lua`) |
| Agent keys | Use `Space + a...` prefix — no conflicts |
| `Space + tt` | Still opens bash terminal (not the agent) |
| Agent toggle | `Space + ai` — open/close agent window |
| Agent layout | `Space + af` / `av` / `ah` — float, vertical, or horizontal split |

## Inside the Agent Terminal

| Shortcut | Action |
|----------|--------|
| `jj` | Exit Neovim terminal insert (for `Space + ...` keys) |
| `Esc` | Agent vimMode: normal mod in prompt (single Esc) |
| `Esc + Esc` | Exit agent terminal to Neovim normal |
| `q` | Close agent window |

**Cursor CLI vimMode** is on in `~/.cursor/cli-config.json`. Single `Esc` edits the prompt; double `Esc` or `jj` leaves the agent terminal.

## Commands (manual)

```
:CursorCliOpen
:CursorCliToggle
:CursorCliOpenWithLayout float|vsplit|hsplit
:CursorCliResume
:CursorCliRestart
:CursorCliNew [name]
:CursorCliSelect
:CursorCliAddSelection
:CursorCliFixErrorAtCursor
```

## Updates and Maintenance

| Command | Purpose |
|---------|---------|
| `:Lazy sync` (inside Neovim) | Update plugins |
| `agent --version` | Check CLI version (keep up to date) |

**Intentionally unused feature:**

- `:CursorCliQuickEdit` — not mapped (security)
