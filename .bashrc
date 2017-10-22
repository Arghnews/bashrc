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

#function parse_git_branch {
#    ref=$(git symbolic-ref HEAD 2>/dev/null) || return
#    echo "("${ref#refs/heads/}")"
#}

#export PS1="\s->\W$ "

#export PS1="\h@\W-> \[$(tput sgr0)\]"

# ezprompt.net for PS1 creation
# get current branch in git repo
function parse_git_branch() {
	BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
	if [ ! "${BRANCH}" == "" ]
	then
		STAT=`parse_git_dirty`
		echo "[${BRANCH}${STAT}]"
	else
		echo "@"
	fi
}

# get current status of git repo
function parse_git_dirty {
	status=`git status 2>&1 | tee`
	dirty=`echo -n "${status}" 2> /dev/null | grep "modified:" &> /dev/null; echo "$?"`
	untracked=`echo -n "${status}" 2> /dev/null | grep "Untracked files" &> /dev/null; echo "$?"`
	ahead=`echo -n "${status}" 2> /dev/null | grep "Your branch is ahead of" &> /dev/null; echo "$?"`
	newfile=`echo -n "${status}" 2> /dev/null | grep "new file:" &> /dev/null; echo "$?"`
	renamed=`echo -n "${status}" 2> /dev/null | grep "renamed:" &> /dev/null; echo "$?"`
	deleted=`echo -n "${status}" 2> /dev/null | grep "deleted:" &> /dev/null; echo "$?"`
	bits=''
	if [ "${renamed}" == "0" ]; then
		bits=">${bits}"
	fi
	if [ "${ahead}" == "0" ]; then
		bits="*${bits}"
	fi
	if [ "${newfile}" == "0" ]; then
		bits="+${bits}"
	fi
	if [ "${untracked}" == "0" ]; then
		bits="?${bits}"
	fi
	if [ "${deleted}" == "0" ]; then
		bits="x${bits}"
	fi
	if [ "${dirty}" == "0" ]; then
		bits="!${bits}"
	fi
	if [ ! "${bits}" == "" ]; then
		echo " ${bits}"
	else
		echo ""
	fi
}

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


