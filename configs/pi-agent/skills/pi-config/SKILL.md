---
name: pi-config
description: Manage pi harness configuration (settings, themes, prompts, skills) which lives in the dotfiles repo and is symlinked into ~/.pi/agent. Use when adding or changing pi configuration, themes, prompt templates, or skills.
---

# Pi config management

Pi's user-level config lives in the dotfiles repo and is symlinked into `~/.pi/agent/`.

- Source of truth: `configs/pi-agent/` in this repo
- Symlinked into `~/.pi/agent/`: `settings.json`, `AGENTS.md`, `themes/`, `prompts/`, `skills/`
- Never tracked: `auth.json`, `sessions/`, `models-store.json`, `bin/`, `install/` (machine state; guarded in the repo's `.gitignore`)

## Workflow

1. Edit files under `configs/pi-agent/` — treat the repo as home, not `~/.pi/agent/`.
2. After adding a new top-level item (e.g. a new directory), re-link with:
   `bash scripts/link-configs.sh pi` (from the repo root)
3. Tell the user to run `/reload` in pi to pick up the changes.
4. Commit and push so the change is tracked.

## Notes

- A live pi session can rewrite `settings.json` through the symlink (e.g. after `/settings` edits). Check `git status` in the dotfiles repo and commit those changes too instead of clobbering them.
- Prompt templates are Markdown files in `prompts/`; the filename becomes the `/command`. Skills are directories with a `SKILL.md`.
