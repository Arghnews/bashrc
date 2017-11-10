if [ -r ~/.workrc.sh ]; then
    #echo "Loading workrc"
    . ~/.workrc.sh
    #echo "Loaded workrc"
    # echoing here breaks dmake
else
    #echo "Could not find workrc"
    :
fi

set -o vi

# linewrapping
export TERM="xterm-256color"

function parse_git_branch {
    local ref=$(git symbolic-ref HEAD 2>/dev/null)
    if [ -z "$ref" ]; then
      echo "@"
    else
      echo "("${ref#refs/heads/}")"
    fi
}

#export PS1="\s->\W$ "

#export PS1="\h@\W-> \[$(tput sgr0)\]"

# ezprompt.net for PS1 creation
# get current branch in git repo
# TODO: this git crap from this site is sooo slow
# subshells problem?
# think actually git status is slow as poop
export PS1="\[\e[36m\]\h\[\e[m\]\[\e[32m\]\`parse_git_branch\`\[\e[m\]\[\e[31m\]\W\[\e[m\]\\$ "


alias grep="grep --color=auto"
alias ls="ls --color=auto"

# no displaying hidden files when pressing tab
bind "set match-hidden-files off"

#complete -o default -W "$(cmd list-of-tabs)" cmd

alias json="python -mjson.tool"

function da() {
    date "+%Y%m%d"
}
export -f da

# prettier git log using git lg
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)' --abbrev-commit"

function touchy() {
    [ -f "$1" ] && return 0
    {
    echo "#!/usr/bin/env bash"
    echo ""
    echo "set -euf -o pipefail"
    echo ""
    chmod u+x "$1"
    } > "$1"
    # e - exit on command fail
    # u - unset var = exit
    # f - disable globbing - shopt -s failglob - for non-expanded globs to err
    # set -o pipefail - if any command in a pipeline errors, script exits
}
export -f touchy

# disables default ctrl + S sending XOF pause
# allows use of it while reverse searching
stty -ixon

alias st="git status"

# trying for now, more powerful pattern matching
# eg ls !(dont_see_me*)
shopt -s extglob

# see all tracked files on current branch
function gitls() {
    local b=$(git branch | grep '*')
    # remove prefix
    b=${b#* }
    git ls-tree -r "$b" --name-only
}
export -f gitls

# to move about more easily
# ie. save y; cd ./././aslda; cd...
# load y
function save() {
    local in="$1"
    if [ -z "$in" ]; then
        in="b3c18ccb909a4d6d8b73535124a5130c"
    fi
    local cmd="$in=$(pwd)"
    eval "$cmd"
    export "$in"
}
export -f save

function load() {
    local in="$1"
    if [ -z "$in" ]; then
        in="b3c18ccb909a4d6d8b73535124a5130c"
    fi
    local cmd="cd \$$in"
    eval "$cmd"
}
export -f load

function swap() {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Provide two files to swap"
    fi
    tmp=$(mktemp)
    mv "$1" "$tmp"
    mv "$2" "$1"
    mv "$tmp" "$2"
}
export -f swap

# increase history line limit and file size limit
shopt -s histappend
HISTFILESIZE=5000000
HISTSIZE=25000
