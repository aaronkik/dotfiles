## Coding Style
- Never add code comments for self describing code. The only exception is that it provides business value or the next person wouldn't be able to know why a decision was made without identify the git history. Code comments should be succinct and tautological.
- Code should be self documenting.
- Code should have low cyclomatic complexity.
- Prefer early returns in functions.
- When removing code from a codebase, don't add a test to cover the removed code.
- No tautological tests.

## Tooling to use
- Git worktrees (worktrunk `wt`)
- Interacting with GitHub `gh`
