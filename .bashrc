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
    ref=$(git symbolic-ref HEAD 2>/dev/null) || return
    echo "("${ref#refs/heads/}")"
}

#export PS1="\s->\W$ "
export PS1="\h@\W-> \[$(tput sgr0)\]"

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


