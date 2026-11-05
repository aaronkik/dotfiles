#!/usr/bin/env bash
set -euo pipefail

readonly CLASSIFY='
{
  branch,
  path: .worktree.path,
  current: .worktree.current,
  integrated: (.default_branch.integration != null),
  dirty: ([(.worktree.changes // {}) | to_entries[] | select(.key != "diff") | .value] | any)
}
| .reasons = [
    (if .branch == null then "detached HEAD" else empty end),
    (if .dirty then "uncommitted changes" else empty end),
    (if (.integrated | not) and $unpushed > 0 then "\($unpushed) unpushed commit(s)" else empty end)
  ]
| {branch, path, current, safe: (.reasons | length == 0), reasons}
'

unpushed_count() {
  [[ -z $1 ]] && { echo 0; return; }
  git rev-list --count "$1" --not --remotes
}

classify_worktrees() {
  jq -c '.items[] | select(.worktree and (.worktree.main | not))' <<<"$1" |
    while IFS= read -r item; do
      local branch
      branch=$(jq -r '.branch // empty' <<<"$item")
      jq -c --argjson unpushed "$(unpushed_count "$branch")" "$CLASSIFY" <<<"$item"
    done
}

git fetch --all --prune --quiet || echo "warning: fetch failed; remote state may be stale" >&2

listing=$(wt list --format=json)
main_worktree=$(jq -r '.items[] | select(.worktree.main) | .worktree.path' <<<"$listing")

classify_worktrees "$listing" | jq -s --arg main "$main_worktree" '{main_worktree: $main, worktrees: .}'
