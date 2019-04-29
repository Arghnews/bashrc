set -o vi

# linewrapping
#export TERM="xterm-256color"
export TERM="screen-256color"

# increase history line limit and file size limit
shopt -s histappend
export HISTFILESIZE=5000000
export HISTSIZE=250000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

#export PS1="\s->\W$ "

#export PS1="\h@\W-> \[$(tput sgr0)\]"

# ezprompt.net for PS1 creation
# https://stackoverflow.com/a/3058390/8594193
LIGHT_RED="\[\033[1;31m\]"
RESTORE="\[\033[0m\]" #0m restores to the terminal's default colour

# Run every time command is hit
# Remove 148 - code 128 + signal SIGTSTP - every time hit control-z
# remove exit code after 2nd press
PROMPT_COMMAND='RET="$?"; ERR_MSG=""; if [ $RET -ne 0 ] && [ $RET -ne 148 ]; then ERR_MSG=" $RET "; fi'
export PS1="\[\e[36m\]\h\[\e[m\]\[\e[32m\]\$(parse_git_branch)\\[\e[m\]\[\e[31m\]\W\[\e[m\]$LIGHT_RED\$ERR_MSG${RESTORE}$ "

alias grep="grep --color=auto"
alias ls="ls --color=auto"

alias pgrep="pgrep --list-full"

# no displaying hidden files when pressing tab
bind "set match-hidden-files off"

#complete -o default -W "$(cmd list-of-tabs)" cmd
alias json="python -mjson.tool"

export SHELL=/bin/bash

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

function da()
{
    date "+%Y%m%d"
}

function m()
{
    make && ./program
}

function parse_git_branch
{
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

function contains()
{
    # String $1 contains substring $2
    case "$1" in *"$2"*) return 0;; esac
    return 1
}

function touchy()
{
    [ -f "$1" ] && echo_err "File exists: $1" && return 1
    {
        echo "#!/usr/bin/env bash"
        echo ""
        echo "set -u -o pipefail"
        echo ""
    } > "$1"
    # e - exit on command fail
    # u - unset var = exit
    # f - disable globbing - shopt -s failglob - for non-expanded globs to err
    # set -o pipefail - if any command in a pipeline errors, script exits
    # could do this with read/heredoc instead
    chmod u+x "$1"
}

# See all tracked files on current branch
function gitls()
{
    local b=$(git branch | grep '*')
    # Remove prefix
    b=${b#* }
    git ls-tree -r "$b" --name-only
}

function swap()
{
    # TODO: breaks if ROOT ISSEUES
    # CURRENTLY THIS BREAKS IF BOTH FILED ARE OWNED BY ROOT and you're not root
	# Swaps either two files or directories
    if { ! [[ -f "$1" && -f "$2" ]] && ! [[ -d "$1" && -d "$2" ]]; } \
		|| [[ "$1" == "$2" ]] ; then
        echo_err "Provide two files/directories to swap" && return 1
    fi
	echo "Swapping $1 and $2"
	local tmp=""
	if [[ -f "$1" ]]; then tmp="$(mktemp)"; else tmp="$(mktemp -d)"; fi
    local mver="mv -T"
	local exit_status=0
    $mver "$1" "$tmp" && $mver "$2" "$1" && sudo $mver "$tmp" "$2"
	local exit_status=$?
	[[ "$exit_status" -ne 0 ]] && echo_err "Something went wrong with swap -"\
		"temporary path to what may be swapped file: $tmp"
    return $exit_status
}

function ccc()
{
    # Urgh, installed boost myself on ubuntu 18.10 into /usr/local (include,
    # lib) then use time - get linker issues, urgh
    # Look into header only boost? Or shared (but then still need args I think)
    # ccc -O3 t.cpp -L/usr/local/lib -lboost_timer -lboost_chrono -Wl,-rpath=/usr/local/lib --

    local compiler executable_name
    declare -a user_compiler_args program_args filenames \
        compiler_default_args_to_add

    declare -A compiler_arg_defaults
    compiler_arg_defaults["-O.*"]="-O2"
    compiler_arg_defaults["-march=.*"]="-march=native"
    compiler_arg_defaults["-std=.*"]="-std=c++17"


    # Find compiler
    # if contains "$PATH" " "
    contains "$PATH" " " && echo_err "Spaces in \$PATH unsupported" && return 1
    if [ -z "$compiler" ]
    then
        compiler="$(find ${PATH//:/ } -maxdepth 1 \( -type f -o -type l \) \
            \( -name clang++* \) 2>/dev/null | sort -uV | tail -n 1)"
    fi
    if [ -z "$compiler" ]
    then
        compiler="$(which g++)"
    fi
    if [ -z "$compiler" ]
    then
        echo_err "Could not find clang++ or g++ compiler in \$PATH" && return 1
    fi


    # Fill compiler and user args from command line
    for arg in "$@"
    do
        case "$arg" in
            --)
                user_compiler_args=(
                                    "${user_compiler_args[@]}"
                                    "${program_args[@]}"
                                    )
                program_args=()
                ;;
            *) program_args+=("$arg");;
        esac
    done


    # Extract and remove filenames mutating compiler args (or user args if not
    # provided); find executable name
    declare -a non_filenames
    declare -n args=user_compiler_args

    # declare -n requires bash > 4.3 (check BASH_VERSINFO array)
    # If not can just search through both
    # ie. args=("$program_args{[@]}" "${user_compiler_args[@]}")
    if [ "${#user_compiler_args[@]}" -eq 0 ]
    then
        declare -n args=program_args
    fi
    for arg in "${args[@]}"
    do
        case "$arg" in
            *.c|*.cpp|*.cxx) filenames+=("$arg");;
            *) non_filenames+=("$arg");;
        esac
    done
    args=("${non_filenames[@]}")

    [ "${#filenames[@]}" -eq 0 ] && echo_err "Could not find filename" \
        && return 1
    executable_name="${filenames[0]%.*}"


    # Find if -o specified and if so don't append it and extract executable name
    for ((i = 0; i < ${#user_compiler_args[@]}; ++i))
    do
        if [ "${user_compiler_args[$i]}" = "-o" ]
        then
            declare -i next=$(( i + 1 ))
            [ "${#user_compiler_args[@]}" -eq "$next" ] && \
                echo_err "No executable name to -o compile option" && return 1
            executable_name="${user_compiler_args[$next]}"
            break
        fi
    done

    # Add compiler output executable argument if not present
    compiler_arg_defaults["-o"]="-o $executable_name"


    # Find and save arguments that are absent and default values should be used
    for default in "${!compiler_arg_defaults[@]}"
    do
        add_default=true
        regex="^${default}$"
        declare -i i
        for ((i = 0; i < ${#user_compiler_args[@]}; ++i))
        do
            # echo "Compiler arg ${user_compiler_args[$i]}"
            if [[ "${user_compiler_args[$i]}" =~ $regex ]]
            then
                add_default=false
                break
            fi
        done
        if [ "$add_default" = true ]
        then
            compiler_default_args_to_add+=("${compiler_arg_defaults[$default]}")
        fi
    done


    # Compiler flags that are always added
    declare -a compiler_flags=(
                    "-g"
                    "-Wall"
                    "-Wextra"
                    "-pedantic"
                    "-Wfloat-equal"
                    "-Wwrite-strings"
                    "-Wswitch-enum"
                    "-Wunreachable-code"
                    "-Wconversion"
                    "-Wcast-qual"
                    "-Wstrict-overflow=5"
                    "-Werror=shadow"
                    "-fverbose-asm"
                    "-lstdc++fs"
                    )


    # Actual cmds
    declare -a compile_cmd=(
                    "${compiler}"
                    "${compiler_flags[@]}"
                    "${compiler_default_args_to_add[@]}"
                    "${user_compiler_args[@]}"
                    "${filenames[@]}"
                    )

    if ! contains "$executable_name" "/"
    then
        executable_name="./$executable_name"
    fi
    declare -a program_cmd=(
                    "$executable_name"
                    "${program_args[@]}"
                    )

    ${compile_cmd[@]} && ${program_cmd[@]}
}

function touchcpp()
{
    : "${1?"Provide cpp filename"}"
    [ -f "$1" ] && echo_err "File with name $1 exists" && return 1

    # Assumes file spacing is 2 spaces
    local space="  "
    # Using <<- with the dash to disable leading tabs - see heredoc
    cat <<- EOF >> "$1"
		#include <algorithm>
		#include <cassert>
		#include <iostream>
		#include <string>
		#include <vector>

		//#include "prettyprint.hpp"

		using namespace std::literals;

		int main (int /*argc*/, char** /*argv*/)
		{
		${space}std::cout << std::boolalpha;
		${space}std::cout << "Hello world!" << "\n";
		}
	EOF
}

function touchpy3()
{
    : "${1?"Provide py filename"}"
    [ -f "$1" ] && echo_err_exit "File with name $1 exists"

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
    excludes+="-E *.vim -E *.d -E ~.* -E *.d -E tags"
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow $excludes "
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# http://wiki.bash-hackers.org/syntax/pe
