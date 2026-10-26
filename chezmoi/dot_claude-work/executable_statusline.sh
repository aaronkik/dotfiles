#!/usr/bin/env bash
# Claude Code status line — Catppuccin Frappe theme with Nerd Font icons

set -euo pipefail

# --- Colors (Catppuccin Frappe, true color ANSI) ---
C_CLAUDE='\033[38;2;217;119;87m'
C_BLUE='\033[38;2;140;170;238m'
C_LAVENDER='\033[38;2;186;187;241m'
C_SAPPHIRE='\033[38;2;133;193;220m'
C_GREEN='\033[38;2;166;209;137m'
C_YELLOW='\033[38;2;229;200;144m'
C_PEACH='\033[38;2;239;159;118m'
C_RED='\033[38;2;231;130;132m'
C_TEAL='\033[38;2;129;200;190m'
C_SKY='\033[38;2;153;209;219m'
C_MAROON='\033[38;2;234;153;156m'
C_MAUVE='\033[38;2;202;158;230m'
C_FLAMINGO='\033[38;2;238;190;190m'
C_OVERLAY0='\033[38;2;115;121;148m'
C_TEXT='\033[38;2;198;208;245m'
C_SUBTEXT0='\033[38;2;165;173;206m'
C_RESET='\033[0m'

# --- Read JSON from stdin ---
JSON=$(cat)

# --- Helper: format token count with K suffix ---
fmt_tokens() {
  local n=${1:-0}
  if [[ $n -ge 1000000 ]]; then
    printf '%.2fM' "$(echo "$n / 1000000" | bc -l)"
  elif [[ $n -ge 1000 ]]; then
    printf '%.2fK' "$(echo "$n / 1000" | bc -l)"
  else
    printf '%d' "$n"
  fi
}

fmt_tokens_whole() {
  local n=${1:-0}
  if [[ $n -ge 1000000 ]]; then
    printf '%dM' "$((n / 1000000))"
  elif [[ $n -ge 1000 ]]; then
    printf '%dK' "$((n / 1000))"
  else
    printf '%d' "$n"
  fi
}

# --- Helper: format duration from ms to Xm Ys ---
fmt_duration() {
  local ms=${1:-0}
  local total_s=$((ms / 1000))
  local m=$((total_s / 60))
  local s=$((total_s % 60))
  if [[ $m -gt 0 ]]; then
    printf '%dm %ds' "$m" "$s"
  else
    printf '%ds' "$s"
  fi
}

# --- Git info (cached 5s) ---
CACHE_FILE="/tmp/claude-statusline-git-cache"
CACHE_TTL=5
git_branch=""
git_remote_url=""
git_repo_name=""
git_https_url=""
git_remote_type=""

load_git_info() {
  local now
  now=$(date +%s)
  if [[ -f "$CACHE_FILE" ]]; then
    local mtime
    mtime=$(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)
    if (( now - mtime < CACHE_TTL )); then
      # shellcheck disable=SC1090
      source "$CACHE_FILE"
      return
    fi
  fi

  git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
  git_remote_url=$(git remote get-url origin 2>/dev/null || echo "")
  git_repo_name=""
  git_https_url=""
  git_remote_type="git"

  if [[ -n "$git_remote_url" ]]; then
    # Convert SSH to HTTPS and detect remote type
    if [[ "$git_remote_url" == git@github.com:* ]]; then
      local path="${git_remote_url#git@github.com:}"
      path="${path%.git}"
      git_https_url="https://github.com/${path}"
      git_repo_name="${path##*/}"
      git_remote_type="github"
    elif [[ "$git_remote_url" == git@bitbucket.org:* ]]; then
      local path="${git_remote_url#git@bitbucket.org:}"
      path="${path%.git}"
      git_https_url="https://bitbucket.org/${path}"
      git_repo_name="${path##*/}"
      git_remote_type="bitbucket"
    elif [[ "$git_remote_url" == https://* ]]; then
      git_https_url="${git_remote_url%.git}"
      local path="${git_https_url#https://*/}"
      git_repo_name="${path##*/}"
      if [[ "$git_remote_url" == *github.com* ]]; then
        git_remote_type="github"
      elif [[ "$git_remote_url" == *bitbucket.org* ]]; then
        git_remote_type="bitbucket"
      fi
    else
      git_repo_name="$git_remote_url"
      git_https_url=""
    fi
  fi

  cat > "$CACHE_FILE" <<CACHE
git_branch=$(printf '%q' "$git_branch")
git_remote_url=$(printf '%q' "$git_remote_url")
git_repo_name=$(printf '%q' "$git_repo_name")
git_https_url=$(printf '%q' "$git_https_url")
git_remote_type=$(printf '%q' "$git_remote_type")
CACHE
}

load_git_info

# --- Parse JSON with single jq call ---
eval "$(echo "$JSON" | jq -r '
  @sh "model_name=\(.model.display_name // "Unknown")",
  @sh "version=\(.version // "?")",
  @sh "ctx_pct_raw=\(.context_window.used_percentage // 0)",
  @sh "ctx_pct=\(.context_window.used_percentage // 0 | floor)",
  @sh "ctx_max=\(.context_window.context_window_size // 200000)",
  @sh "total_duration=\(.cost.total_duration_ms // 0)",
  @sh "input_tokens=\(.context_window.total_input_tokens // 0)",
  @sh "output_tokens=\(.context_window.total_output_tokens // 0)",
  @sh "has_worktree=\(if .worktree != null then "true" else "false" end)",
  @sh "wt_name=\(.worktree.name // "")",
  @sh "wt_path=\(.worktree.path // "")",
  @sh "wt_branch=\(.worktree.branch // "")"
')"

# --- Build & output lines ---
SEP="${C_OVERLAY0}  ${C_RESET}"

# --- Line 1: Model & Git ---
line1="${C_CLAUDE}\xe2\x9c\xb3 ${model_name} \xe2\x80\x94 v${version}${C_RESET}"
if [[ -n "$git_branch" ]]; then
  line1+="${SEP}${C_LAVENDER}\xee\x9c\xa5 ${git_branch}${C_RESET}"
fi
if [[ -n "$git_repo_name" ]]; then
  # Remote icon: GitHub, Bitbucket, or generic Git
  case "$git_remote_type" in
    github)    remote_icon='\xef\x82\x9b' ;;
    bitbucket) remote_icon='\xee\x9c\x83' ;;
    *)         remote_icon='\xef\x87\x93' ;;
  esac
  if [[ -n "$git_https_url" ]]; then
    osc_start='\033]8;;'
    osc_end='\033\134'
    line1+="${SEP}${osc_start}${git_https_url}${osc_end}"
    line1+="${C_SAPPHIRE}${remote_icon} ${git_repo_name}${C_RESET}"
    line1+="${osc_start}${osc_end}"
  else
    line1+="${SEP}${C_SAPPHIRE}${remote_icon} ${git_repo_name}${C_RESET}"
  fi
fi
printf '%b' "$line1"

# --- Worktree line (conditional) ---
if [[ "$has_worktree" == "true" ]]; then
  wt_line="${C_FLAMINGO}󰙅 ${wt_name}${C_RESET}"
  if [[ -n "$wt_path" ]]; then
    wt_line+="${SEP}${C_FLAMINGO} ${wt_path}${C_RESET}"
  fi
  if [[ -n "$wt_branch" ]]; then
    wt_line+="${SEP}${C_FLAMINGO} ${wt_branch}${C_RESET}"
  fi
  printf '\n'
  printf '%b' "$wt_line"
fi

# --- Context bar line ---
filled=$((ctx_pct * 20 / 100))
empty=$((20 - filled))
bar=""
for ((i = 0; i < filled; i++)); do bar+="█"; done
for ((i = 0; i < empty; i++)); do bar+="░"; done

if [[ $ctx_pct -ge 90 ]]; then
  bar_color="$C_RED"
elif [[ $ctx_pct -ge 80 ]]; then
  bar_color="$C_PEACH"
elif [[ $ctx_pct -ge 50 ]]; then
  bar_color="$C_YELLOW"
else
  bar_color="$C_GREEN"
fi

ctx_line="${C_TEXT} ${bar_color}${bar} ${ctx_pct}%${C_RESET}"
ctx_line+="${SEP}${C_SUBTEXT0}\xe2\x8f\xb3 $(fmt_duration "$total_duration")${C_RESET}"
printf '\n'
printf '%b' "$ctx_line"

# --- Token stats line ---
context_tokens=$(echo "$ctx_max * $ctx_pct_raw / 100" | bc | cut -d. -f1)
tok_line="${C_TEXT}\xce\xa3 $(fmt_tokens "$context_tokens")${C_RESET}"
tok_line+="${SEP}${C_SKY}\xef\x85\xb6 $(fmt_tokens "$input_tokens")${C_RESET}"
tok_line+="${SEP}${C_MAROON}\xef\x85\xb5 $(fmt_tokens "$output_tokens")${C_RESET}"
tok_line+="${SEP}${C_TEAL}\xf0\x9f\xa7\xa0 $(fmt_tokens_whole "$ctx_max")${C_RESET}"
printf '\n'
printf '%b' "$tok_line"
