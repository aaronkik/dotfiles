alias c=clear
alias epoch='date +%s'
alias iso='epoch | jq --raw-output todate | pbcopy'
alias l=eza
alias ls='eza --all --git-repos --header --icons --long --no-permissions --no-filesize --no-user --time-style relative'
alias h='history -E'
alias jj='pbpaste | jsonpp -s | pbcopy'
alias rm=trash
alias s='source ~/.zshrc'
alias to_epoch='pbpaste | jq --raw-output fromdate | pbcopy'
alias to_iso='pbpaste | jq --raw-output todate | pbcopy'
alias to_json='pbpaste | jq --raw-output fromjson | pbcopy'
alias to_string='pbpaste | jq --raw-output tostring | pbcopy'
alias ide='goland nosplash'
alias uuid='uuidgen | tr -d "\n" | tr "[:upper:]" "[:lower:]" | pbcopy'

# Git aliases
alias sw='git switch'
alias swc='git switch --create'
alias gr='git restore'
alias gs='git status'
alias ga='git add'
alias gap='git add -p'
alias gc='git commit'
alias gl=pretty_git_log
alias gla=pretty_git_log_all
alias gp='git push'
alias gpn='git push --no-verify'
alias grpo='git remote prune origin'
alias ff='grpo && git pull --ff-only'
