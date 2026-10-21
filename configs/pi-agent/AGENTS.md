# Global Instructions

## Language

- Match the user's language: reply in Turkish when they write Turkish, English when they write English.
- Code, comments, commit messages, and identifiers stay in English unless the user asks otherwise.

## General behavior

- Be concise and direct. Skip filler and unnecessary summaries.
- Show file paths clearly when working with files.
- Prefer small, focused edits over large rewrites.
- Run tests/builds to verify changes when the project has them.
- Never commit or push unless the user explicitly asks.

## Tooling preferences

- Node projects: use `pnpm` (via `corepack pnpm` if pnpm is not on PATH).
- Task runner: if a `Justfile` exists, prefer `just` recipes over ad-hoc commands.
- Search: prefer `rg` over `grep`, `fd` over `find` when available.

## Safety

- Do not touch files outside the working directory unless asked.
- Be careful with destructive commands (`rm -rf`, `git reset --hard`, db resets) — confirm first.
