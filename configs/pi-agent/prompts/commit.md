---
description: Create a conventional commit for staged changes
argument-hint: "[scope]"
---
Create a git commit for the currently staged changes.

1. Run `git diff --staged` to see what changed.
2. Write a conventional commit message: `type(scope): summary`. Use `$1` as the scope if given; otherwise infer it from the changed files or omit it. Keep the summary under 72 chars, imperative mood. Add a short body only when the why is not obvious.
3. If nothing is staged, show `git status` and ask what to stage — do not guess.
4. Commit, then show the result with `git log --oneline -1`.
