mkcd() {
    mkdir -p "$1"
    cd "$1"
}

source_if_exists () {
    if test -r "$1"; then
        source "$1"
    fi
}
