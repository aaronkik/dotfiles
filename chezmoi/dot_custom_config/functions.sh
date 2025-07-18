mkcd() {
    mkdir -p "$1"
    cd "$1" || exit
}

source_if_exists () {
    if test -r "$1"; then
       source "$1"
    fi
}

################################################################################
# GIT FUNCTIONS ################################################################
################################################################################

gbr () {
    git checkout -b "$1"
    git push -u origin "$1"
}

gbd () {
    git branch -D "$1"
}

gbdr () {
    git branch -D "$1"
    git push origin --delete "$1"
}

gcm () {
    git commit -m "$*"
}

gcmp () {
    git commit -m "$*"
    git push
}

# Copied from Gary Bernhardt (destroyallsoftware.com) dot files repository.
#
# Log output:
#
# * 51c333e    (12 days)    <Gary Bernhardt>   add vim-eunuch
#
# Branch output:
#
# * release/v1.1    (13 days)    <Leyan Lo>   add pretty_git_branch
#
# The time massaging regexes start with ^[^<]* because that ensures that they
# only operate before the first "<". That "<" will be the beginning of the
# author name, ensuring that we don't destroy anything in the commit message
# that looks like time.
#
# The log format uses } characters between each field, and `column` is later
# used to split on them. A } in the commit subject or any other field will
# break this.

LOG_HASH="%C(always,yellow)%h%C(always,reset)"
LOG_RELATIVE_TIME="%C(always,green)(%ar)%C(always,reset)"
LOG_AUTHOR="%C(always,blue)<%an>%C(always,reset)"
LOG_REFS="%C(always,red)%d%C(always,reset)"
LOG_SUBJECT="%s"

LOG_FORMAT="$LOG_HASH}$LOG_AUTHOR}$LOG_RELATIVE_TIME}$LOG_SUBJECT $LOG_REFS"

BRANCH_PREFIX="%(HEAD)"
BRANCH_REF="%(color:red)%(color:bold)%(refname:short)%(color:reset)"
BRANCH_HASH="%(color:yellow)%(objectname:short)%(color:reset)"
BRANCH_DATE="%(color:green)(%(committerdate:relative))%(color:reset)"
BRANCH_AUTHOR="%(color:blue)%(color:bold)<%(authorname)>%(color:reset)"
BRANCH_CONTENTS="%(contents:subject)"

BRANCH_FORMAT="}$BRANCH_PREFIX}$BRANCH_REF}$BRANCH_HASH}$BRANCH_DATE}$BRANCH_AUTHOR}$BRANCH_CONTENTS"

show_git_head() {
    pretty_git_log -1
    git show -p --pretty="tformat:"
}

pretty_git_log() {
    git log --since="6 months ago" --graph --pretty="tformat:${LOG_FORMAT}" $* | pretty_git_format | git_page_maybe
}

pretty_git_log_all() {
    git log --all --since="6 months ago" --graph --pretty="tformat:${LOG_FORMAT}" $* | pretty_git_format | git_page_maybe
}


pretty_git_branch() {
    git branch -v --color=always --format=${BRANCH_FORMAT} $* | pretty_git_format
}

pretty_git_branch_sorted() {
    git branch -v --color=always --format=${BRANCH_FORMAT} --sort=-committerdate $* | pretty_git_format
}

pretty_git_format() {
    # Replace (2 years ago) with (2 years)
    sed -Ee 's/(^[^)]*) ago\)/\1)/' |
    # Shorten names
    sed -Ee 's/<Aaron Kikabhai>/<me>/' |
    sed -Ee 's/<([^ >]+) [^>]*>/<\1>/' |
    # Line columns up based on } delimiter
    column -s '}' -t
}

git_page_maybe() {
    # Page only if we're asked to.
    if [ -n "${GIT_NO_PAGER}" ]; then
        cat
    else
        # Page only if needed.
        less --quit-if-one-screen --no-init --RAW-CONTROL-CHARS --chop-long-lines
    fi
}


delete_aws_stacks() {
    local PREFIX=$1
    local EXECUTE=false

    if [ -z "$1" ]; then
        echo "Please supply a stack name prefix" >&2
        exit 1
    fi

    if echo "$PREFIX" | grep -qiE "prod|staging"; then
        echo "ERROR: The prefix contains a restricted environment keyword (prod, staging)." >&2
        exit 1
    fi

    if [[ "$2" == "--execute" ]]; then
        EXECUTE=true
    fi

    STACKS=$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE \
        --query "StackSummaries[?starts_with(StackName, \`${PREFIX}\`)].StackName" --output text) | jq -r '.[]'

    # echo -e "Stacks found: $STACKS"
    # echo -e "Removing prod/staging"

    # STACKS=$(echo $STACKS | jq '.[] | select(contains("prod") | not))')
    # echo -e "Filtered stacks: $STACKS"


    if [ -z "$STACKS" ]; then
        echo "No stacks found with prefix: $PREFIX" >&2
        exit 0
    fi

    for STACK in $STACKS; do
        echo "Will delete stack: $STACK" >&2
        if [ "$EXECUTE" = true ]; then
       	aws cloudformation delete-stack --stack-name "$STACK"
    	echo "Deleting stack: $STACK" >&2
        fi
    done

    echo "Deletion initiated for all matching stacks." >&2
}
