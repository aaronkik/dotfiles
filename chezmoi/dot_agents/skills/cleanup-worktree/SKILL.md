---
name: cleanup-worktree
description: >
  Clean up finished git worktrees with `wt remove` once their work is pushed. Use when the user is done with a
  worktree or branch, wants old worktrees removed, or wants to free disk space taken by worktrees, even if they
  don't mention `wt`.
allowed-tools: Bash(wt list *) Bash(wt remove *) Bash(git fetch *) Bash(git rev-list *)
---

# Clean up worktrees

Remove worktrees whose work is safely on the remote, using worktrunk (`wt`). The goal is to clear clutter without
ever losing work: a worktree only goes when nothing is uncommitted and every commit is on a remote or already merged.

## 1. Check what is safe

From inside the repo (whichever worktree the session is in), run:

```bash
{SKILLBASE}/scripts/worktree-status.sh
```

It fetches with `--prune`, then classifies every non-main worktree:

```json
{
  "main_worktree": "/Users/me/code/app",
  "worktrees": [
    { "branch": "feat-login", "path": "/Users/me/code/app.feat-login", "current": true, "safe": true, "reasons": [] },
    { "branch": "fix-header", "path": "/Users/me/code/app.fix-header", "current": false, "safe": false,
      "reasons": ["uncommitted changes", "2 unpushed commit(s)"] }
  ]
}
```

`safe` means no staged, modified or untracked files, and every commit is either on a remote-tracking branch or
already integrated into the default branch. The second case covers squash merges where the remote branch was
auto-deleted.

## 2. Pick the targets

- A branch or path the user named: that worktree.
- "This worktree", or no name given: the one with `current: true`. If none is current, the session is in the main
  worktree; show the list and ask which one they mean.
- "All", "finished", "everything that's pushed": every `safe` worktree.

The main worktree is never a target.

## 3. Stop on anything unsafe

Leave an unsafe target in place and tell the user why, showing the specifics (`git -C <path> status --short`,
`git -C <path> log --oneline HEAD --not --remotes`). Don't reach for `--force` to
get past it. Those are exactly the cases where removal destroys work that exists nowhere else, so the decision
belongs to the user.

## 4. Remove

Measure the targets first so you can report the storage freed. Ignored files such as `node_modules` and build
output usually make up most of it, and `wt` doesn't report sizes in its JSON:

```bash
du -shc <path> [<path> ...]
```

`du` abbreviates units as `K`, `M` and `G`. Write them out as KB, MB and GB whenever you show a size to the user,
for example "5.7 MB" rather than "5.7M".

For a sweep, show the safe worktrees you will remove with their sizes, and the unsafe ones you will keep (with
reasons), then get a yes first. Glancing at a bulk deletion beforehand is cheap. A single worktree the user asked for by name, or the
current one, can go straight away once it is safe.

```bash
cd "<main_worktree>" && wt remove --foreground --format=json -D <branch> [<branch> ...]
```

- `-D`: `wt` otherwise keeps a local branch that isn't merged yet, for example while its PR is open. Step 1 already
  proved every commit is on the remote, so the local copy is redundant. `git switch <branch>` brings it back.
- `--foreground`: removal runs in the background by default. Running it in the foreground makes the JSON result
  final.
- `cd` to the main worktree first: if the session lives in a worktree being removed, the shell would otherwise be
  left in a deleted directory.
- Leave remote branches alone, because an open PR still needs its branch.
- Don't add `-y`. If `wt` asks for hook approval, relay that to the user.

## 5. Report

Keep it short: each removed worktree with its branch, size and `branch_outcome`, the total storage freed, and each
kept worktree with the reason. Only count worktrees that were actually removed towards the total.
If the session's own worktree was removed, say its directory is gone and give the main worktree path to continue
from.
