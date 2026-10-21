---
description: Review git changes for issues
argument-hint: "[focus]"
---
Review the current git changes (staged + unstaged; if on a feature branch, the diff vs main).

Focus on ${1:-correctness, security, error handling, and consistency with existing code style}.

Report findings as a numbered list ordered by severity (critical → nit). For each finding: file:line, what is wrong, and a suggested fix. If everything looks good, say so briefly.
