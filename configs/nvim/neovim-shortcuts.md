# Neovim Shortcuts — Panel Navigation, Resizing, and Focus

**Config file:** `~/.config/nvim/lua/vim-options.lua`  
**Leader key:** Space (`vim.g.mapleader = " "`)

## Panel Navigation and Focus

| Shortcut | Action |
|----------|--------|
| `Space + h` | Move left (focus follows) — `<C-w>h` |
| `Space + j` | Move down — `<C-w>j` |
| `Space + k` | Move up — `<C-w>k` |
| `Space + l` | Move right — `<C-w>l` |

`<C-w>` commands both switch panes and move focus — no separate focus key is needed.

## Resize Panes

| Shortcut | Action |
|----------|--------|
| `Space + +` | Increase height by 4 lines |
| `Space + -` | Decrease height by 4 lines |
| `Space + >` | Increase width by 5 columns |
| `Space + <` | Decrease width by 5 columns |

First use `Space + h/j/k/l` to move to a pane, then resize with `Space + +/-` or `Space + </>`.

## Quick Pane Toggle (Terminal ↔ Editor)

| Shortcut | Action |
|----------|--------|
| `Space + Enter` | Move to the pane below; if there is no pane below, move up. Handy for switching quickly between terminal and editor. |

**Note:** `Space + Enter` toggles panes only. Use `Space + ai` to open or close the Cursor Agent window.

## Other Related Shortcuts

| Shortcut | Action |
|----------|--------|
| `Space + f` | Maximize / restore the active window (`ToggleMaximizeWindow`) |
| `Space + sh` | Horizontal split |
| `Space + sv` | Vertical split |
| `Space + tt` | Open terminal below (bash) |
| `Ctrl + n` | Neo-tree file tree (left panel) |
| `Ctrl + l` | Toggle Neo-tree |
| `Ctrl + d` | Close window/buffer (`:q`) |
| `Ctrl + p` | Find files (Telescope) |
| `Space + fg` | Live grep (Telescope) |
| `Space + gd` | Open Diffview (all agent changes) |
| `Space + gh` | Diffview file history |
| `]h` / `[h` | Next / previous changed hunk |
| `Space + gp` | Preview current hunk (popup) |
| `Space + gu` | Undo current hunk (reject agent edit) |
| `Space + gS` | Stage current hunk |
| `Space + cf` | Clang-format (LLVM style) |
| `Space + cr` | Strip CRLF line endings |
| `Space + sk` | Open shortcut cheat sheet (recommended) |
| `Space + ?` | Same cheat sheet (`Shift + ,` on TR keyboard) |
| `:NeovimShortcuts` | Same cheat sheet (command) |

## Typical Workflow

1. `Space + tt` — Open terminal
2. `Space + Enter` or `Space + j/k` — Switch panes
3. `Space + +/-` or `Space + </>` — Resize
4. `Space + f` — Focus and maximize one pane

## Notes

- Press `Space` and wait — which-key shows all leader shortcuts in a popup.
- `Space + sk` opens the full cheat sheet (easiest).
- Or run `:NeovimShortcuts`.

**Lazy / plugins:** run `:Lazy sync` only to install pinned versions from `lazy-lock.json`. Use `:Lazy update` only when you intentionally want plugin upgrades. Git/diff keys (`Space + g...`, `]h`) need a git repo and unstaged changes.

**Boxed `?` icons:** plugins use Nerd Font glyphs. Either install a Nerd Font in your terminal (recommended), or keep the ASCII fallbacks in this config.

- `Space + l` is used for moving to the right pane; `Ctrl + l` toggles Neo-tree.
- When Neo-tree is open, `Space + l` moves to the right pane; `Ctrl + l` closes the tree.

**In terminal mode:**

| Shortcut | Action |
|----------|--------|
| `Esc` or `Ctrl + d` | Return to normal mode / close terminal |
| `jj` | Same as `Esc` in terminal/agent (exit insert) |

## Cursor Agent (cursorcli.nvim)

See [cursorcli-agent.md](./cursorcli-agent.md) for full details.

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
| `Space + ae` | Send error at cursor to agent |
| `Space + aa` | Add visual selection to agent (visual mode) |
| `Space + aA` | New session + send error or selection |

**Note:** Quick Edit is intentionally not mapped (`--print` / `--approve-mcps` risk). Do not run the agent in untrusted repositories.

## Agent Workflow — Select, Send, Review Diff

Use this loop when the agent edits code for you:

1. Open agent beside code: `Space + av` (vertical split), or toggle with `Space + ai`
2. In code buffer, visual-select lines (`V` or `Ctrl+v`)
3. Send selection to agent: `Space + aa`  
   Agent receives `@file:start-end` — type your prompt (e.g. "refactor this")
4. Wait for agent to finish editing files
5. Focus code buffer (`Space + h`) — changes reload automatically (`autoread`)
6. Review changes:
   - **Whole project:** `Space + gd` (Diffview — side-by-side diff)
   - **Line by line:** `]h` / `[h` jump hunks, `Space + gp` preview popup
   - **Reject one hunk:** `Space + gu`
   - **Keep and stage:** `Space + gS`

For a fresh agent session with the selection: visual mode → `Space + aA`.
For an error at cursor instead: `Space + ae`.
