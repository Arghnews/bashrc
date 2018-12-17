set -o vi

# linewrapping
#export TERM="xterm-256color"
export TERM="screen-256color"

# increase history line limit and file size limit
shopt -s histappend
HISTFILESIZE=5000000
HISTSIZE=25000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

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

export SHELL=/bin/bash

alias m="make && ./program"

eval $(dircolors -b "$HOME"/.dircolors)

# now git commits look soo pretty
# Set editor to nvim else vim else vi
editor=vi
command -v vim &>/dev/null && editor=vim
command -v nvim &>/dev/null && editor=nvim
export VISUAL="$editor"
export EDITOR="$editor"

alias nv=nvim

# disables default ctrl + S sending XOF pause
# allows use of it while reverse searching
# condition (bashism) checks for interactive session
# else get loads of stty ioctl errors
[[ $- == *i* ]] && stty -ixon

alias st="git status"

# trying for now, more powerful pattern matching
# eg ls !(dont_see_me*)
shopt -s extglob

alias make="make -j $(nproc)"

PATH=$PATH:$HOME/.bin

# prettier git log using git lg
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)' --abbrev-commit"

function da() {
    date "+%Y%m%d"
}

function parse_git_branch {
    local ref=$(git symbolic-ref HEAD 2>/dev/null)
    if [ -z "$ref" ]; then
        echo "@"
    else
        echo "("${ref#refs/heads/}")"
    fi
}

function echo_err()
{
    echo 1>&2 "$@"
}

function touchy() {
    [ -f "$1" ] && echo_err "File exists: $1" && return 1
    {
        echo "#!/usr/bin/env bash"
        echo ""
        echo "set -euf -o pipefail"
        echo ""
    } > "$1"
    # e - exit on command fail
    # u - unset var = exit
    # f - disable globbing - shopt -s failglob - for non-expanded globs to err
    # set -o pipefail - if any command in a pipeline errors, script exits
    # could do this with read/heredoc instead - see workrc
    chmod u+x "$1"
}

# see all tracked files on current branch
function gitls() {
    local b=$(git branch | grep '*')
    # remove prefix
    b=${b#* }
    git ls-tree -r "$b" --name-only
}

function swap() {
	# Swaps either two files or directories
    if { ! [[ -f "$1" && -f "$2" ]] && ! [[ -d "$1" && -d "$2" ]]; } \
		|| [[ "$1" == "$2" ]] ; then
        echo_err "Provide two files/directories to swap"
        return 1
    fi
	echo "Swapping $1 and $2"
	local tmp=""
	if [[ -f "$1" ]]; then tmp="$(mktemp)"; else tmp="$(mktemp -d)"; fi
    local mver="mv -T"
	local exit_status=0
    $mver "$1" "$tmp" && $mver "$2" "$1" && $mver "$tmp" "$2"
	local exit_status=$?
	[[ "$exit_status" -ne 0 ]] && echo_err "Something went wrong with swap -"\
		"temporary path to what may be swapped file: $tmp" && return 1
}

function ccc()
{
    # TODO: add argument for compiler and program arg passing properly
	# add smarter compiler discovery to search for latest of gcc/clang
	# would be nice to have a way to quickly disable optimisations for faster compile/not
    local cpp="$1"
    local suffix="${cpp##*.}"
    ! [ "$suffix" == "cpp" ] && echo_err "Warning: file suffix not .cpp"
    local name="${cpp%.*}"
    shift
    #echo "$name"
    #dir="$(dirname "$cpp")"
    # For filesystem linkage
    local flags=""
    flags+="-Wall -Wextra -fverbose-asm -Wfloat-equal -Wshadow -Wwrite-strings "
    flags+="-Wswitch-enum -Wunreachable-code -Wconversion -Wcast-qual -Wstrict-overflow=5"
	# Other options from a SO post to also look into
    #local opts="-pedantic -Wall -Wextra -Wcast-align -Wcast-qual -Wctor-dtor-privacy -Wdisabled-optimization -Wformat=2 -Winit-self -Wlogical-op -Wmissing-include-dirs -Wnoexcept -Wold-style-cast -Woverloaded-virtual -Wredundant-decls -Wshadow -Wsign-conversion -Wsign-promo -Wstrict-null-sentinel -Wstrict-overflow=5 -Wswitch-default -Wundef -Wno-error=unused -Werror=return-type"
    clang++-6.0 -g $flags -O2 -std=c++17 "$cpp" -o "$name" -lstdc++fs && "./$name" $@
}

function touchcpp()
{
    : "${1?"Provide cpp filename"}"
    [ -f "$1" ] && echo_err "File with name $1 exists" && return 1

    # Assumes file spacing is 2 spaces
    local space="  "
    # Using <<- with the dash to disable leading tabs - see heredoc
    cat <<- EOF >> "$1"
		#include <iostream>
		
		int main (int /*argc*/, char** /*argv*/)
		{
		${space}std::cout << "Hello world!" << "\n";
		}
	EOF
}

function touchpy3()
{
    : "${1?"Provide py filename"}"
    [ -f "$1" ] && echo_err "File with name $1 exists" && return 1

    # Assumes file spacing is 4 spaces
    local space="    "
    # Using <<- with the dash to disable leading tabs - see heredoc
    cat <<- EOF >> "$1"
		#!/usr/bin/env python3
		
		import sys
		
		def main(argv):
		${space}print("Hello world!")
		
		if __name__ == "__main__":
		${space}sys.exit(main(sys.argv))
	EOF
    chmod u+x "$1"
}

# Use - " if non_empty_dir ~/.vim/after/ftplugin ..."
# Returns 0 on non empty dir, 1 if dir doesn't exit or is empty
function non_empty_dir()
{
    [ -z "$1" ] && echo 1>&2 "First argument must be directory" && exit 1
    (
    shopt -s nullglob dotglob
    local f=("$1"/*)
    if [ "${#f[@]}" -ne 0 ]; then return 0; else return 1; fi
    )
}

function vimrc()
{
    declare -a plugs
    if non_empty_dir ~/.vim/after/ftplugin
    then
        # Enable globbing, restoring setting after
        # Arguably do this for nullglob and dotglob too?
        local f_set="$(if [[ $- =~ f ]]; then echo 0; fi)"
        [[ "$f_set" ]] && set +f
        plugs=(~/.vim/after/ftplugin/*)
        [[ "$f_set" ]] && set -f
    fi
    # Even works with spaces hooray
    $EDITOR -p ~/.vimrc "${plugs[@]}" ~/.bashrc
    unset plugs
}

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if [ "command -v fd 1>/dev/null 2>&1" ]
then
    #let $FZF_DEFAULT_COMMAND = 'ag --hidden --ignore .git -l -g ""'
    excludes="-E *.git -E *.tmp -E *.so -E *.swp -E *.o -E *.obj -E *.pyc "
    excludes+="-E *.vim -E *.d -E ~.* -E *.d"
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow $excludes "
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi


