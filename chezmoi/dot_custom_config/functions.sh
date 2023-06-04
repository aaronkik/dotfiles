mkcd() {
    mkdir -p "$1"
    cd "$1"
}

source_if_exists () {
    if test -r "$1"; then
        source "$1"
    fi
}

################################################################################
# GIT FUNCTIONS ################################################################
################################################################################

gb () {
    git branch "$1"
    git checkout "$1"
}

gbr () {
    git branch "$1"
    git push -u origin "$1"
    git checkout "$1"
}

gbd () {
    git branch -D "$1"
}

gbdr () {
    git branch -D "$1"
    git push origin --delete "$1"
}

gcm () {
    git commit -m "$@"
}

gcmp () {
    git commit -m "$@"
    git push
}

################################################################################