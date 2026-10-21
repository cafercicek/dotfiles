---
description: Run the test suite and fix failures
argument-hint: "[test filter]"
---
Run the project's test suite (${@:-all tests}).

If anything fails:
1. Read the failure output carefully.
2. Diagnose the root cause before editing anything.
3. Fix the minimal amount of code — or the test, if the test is the one that is wrong.
4. Re-run the failing tests until green, then run the full suite once to confirm nothing else broke.
