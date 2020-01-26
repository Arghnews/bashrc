# TODO: split this into multiple files as it's becoming far too big for one

function da()
{
    date "+%Y%m%d"
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

function command_exists()
{
    command -v "$1" &>/dev/null
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

# Appends string to PATH if not present in PATH already
function append_to_path()
{
    for arg in "$@"
    do
        if ! contains "$PATH" "$arg"
        then
            export PATH="$PATH:$arg"
        fi
    done
}

append_to_path "$HOME/.bin" "$HOME/.local/bin"

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
    local b="$(git branch | grep '*')"
    # Remove prefix
    b="${b#* }"
    git ls-tree -r "$b" --name-only
}

function swap()
{
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
    # Hmm.. http://mywiki.wooledge.org/BashFAQ/050

    local compiler executable_name verbose=false compiler_search
    declare -a user_compiler_args program_args filenames \
        compiler_default_args_to_add
    # NOTE: compiler_arg_defaults are added using word splitting ie. "-o a.out"
    # will be added to the compiler arguments as 2 arguments: "-o" and "a.out"

    declare -A compiler_arg_defaults
    # Regex matched to arguments
    # compiler_arg_defaults["-O.*"]="-O2"
    compiler_arg_defaults["-march=.*"]="-march=native"
    compiler_arg_defaults["--?std=.*"]="-std=c++17"


    # Heredoc MUST be indented by actual tabs
    # NOTE: when stealing this - read exits non-zero when it reaches EOF
    # This will cause scripts with set -e (Exit immediately if a command exits
    # with a non-zero status.) to fail on this
    # To fix this append "|| :" - this will gobble all errors though
    # Furthermore note that we currently set -o pipefail meaning appending "| :"
    # will still fail as the exit status of the read (1) will be the final exit
    # status of the command
    read -r -d '' help_string <<- EOF
	--                  If "--" is present, args before it are passed to the
	                        compiler and those after to the program
	--ccc-verbose       Print additional info (eg. compile line)
	--ccc-clang++       Use clang++ - may append ie. --ccc-clang++-9.0
	--ccc-g++           Use g++ - may append ie. --ccc-g++-8
	--help              Print this help
	EOF
    # If called with only 1 argument and it matches a variant of "--help", print
    # help and exit
    if [ "$#" -eq 1 ]; then
        case "$1" in -h|--h|-help|--help)
            echo "$help_string"
            return 0
            ;;
        esac
    fi


    # Fill compiler and user args from command line
    for arg in "$@"
    do
        case "$arg" in
            --)
                user_compiler_args=("${program_args[@]}")
                program_args=()
                ;;
            --ccc-g++*)
                compiler_search="${arg#--ccc-}"
                ;;
            --ccc-clang++*)
                compiler_search="${arg#--ccc-}"
                ;;
            --ccc-verbose)
                verbose=true
                ;;
            --help)
                echo "$help_string"
                return 0
                ;;
            *)
                program_args+=("$arg")
                # echo "Adding program arg: [$arg]"
                ;;
        esac
    done

    # Find compiler
    # This is to find compilers in PATH called things like g++-8 or
    # /usr/bin/clang++-6.0
    # if [ -z "$compiler" ] && [ -n "$compiler_search" ]
    # then
    #     # Find clang if in PATH. This should deal with spaces, newlines and
    #     # globs (they will not be expanded) in PATH and not change dotglob or
    #     # IFS as it's run in a subshell.
    #     compiler="$(
    #         set -f
    #         IFS=: path_arr=($PATH)
    #         find "${path_arr[@]}" -maxdepth 1 \( -type f -o -type l \) \
    #             \( -name "$compiler_search*" \) \
    #             2> >(grep -v \
    #             -e "Permission denied" -e "No such file or directory" >&2) \
    #             | sort -uV | tail -n 1)"
    # fi

    if [ -z "$compiler" ] && [ -n "$compiler_search" ]
    then
        compiler="$(which "$compiler_search")"
        if [ $? -ne 0 ]
        then
            echo >&2 "Could not find $compiler_search in PATH"
        fi
    fi
    if [ -z "$compiler" ]
    then
        compiler="$(which clang++)"
    fi
    if [ -z "$compiler" ]
    then
        compiler="$(which g++)"
    fi

    if [ -z "$compiler" ]
    then
        echo_err "Could not find clang++ or g++ compiler in \$PATH" && return 1
    fi

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
            *.c|*.cpp|*.cxx|*.cc) filenames+=("$arg");;
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
    # This line was -o $executable_name which caused much pain
    # Actually compilers accept -oname but we'll use "-o" "name" as two
    # arguments passed in order because it is less "astonishing" to me
    compiler_arg_defaults["-o"]="-o $executable_name"


    # Find and save arguments that are absent and default values should be used
    for default in "${!compiler_arg_defaults[@]}"
    do
        local add_default=true
        local regex="^${default}$"
        declare -i i
        # echo "Checking default: $default with regex $regex"
        for ((i = 0; i < ${#user_compiler_args[@]}; ++i))
        do
            # echo "Compiler arg ${user_compiler_args[$i]}"
            if [[ "${user_compiler_args[$i]}" =~ $regex ]]
            then
                # echo "Found replacement for $default, not adding it"
                add_default=false
                break
            fi
        done
        if [ "$add_default" = true ]
        then
            # NOTE: this is deliberately unquoted
            compiler_default_args_to_add+=(${compiler_arg_defaults[$default]})
        fi
    done


    # TODO: change the -l stuff to be appended at end ie. the filesystem one -
    # to be clear must be after objects (this shit again)
    # Compiler flags that are always added
    # -Weffc++ - apparently can be overly sensitive. Should warn on
    # uninitialised variables in constructors.
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
                    "-Werror=return-type"
                    "-Wuninitialized"
                    "-Weffc++"
                    "-L/usr/local/lib"
                    "-lfmt"
                    "-pthread"
                    "-fdiagnostics-color"
                    )
    #-fsanitize=address,undefined


    # Actual cmds
    # Putting compiler flags at end for now so options like -lstdc++fs will work
    # Order matters: https://stackoverflow.com/a/409470/8594193
    declare -a compile_args=(
                    "${filenames[@]}"
                    "${compiler_default_args_to_add[@]}"
                    "${user_compiler_args[@]}"
                    "${compiler_flags[@]}"
                    )

    # echo "compiler [${compiler}]"
    # echo "compiler_default_args_to_add [${compiler_default_args_to_add[@]}]"
    # echo "user_compiler_args [${user_compiler_args[@]}]"
    # echo "filenames [${filenames[@]}]"
    # echo "compiler_flags [${compiler_flags[@]}]"

    if ! contains "$executable_name" "/"
    then
        executable_name="./$executable_name"
    fi

    # echo "exec name: [$executable_name]"
    # echo "compile args: [${compile_args[@]}]"
    # echo "program args: [${program_args[@]}]"
    # echo "program args len: ${#program_args[@]}"

    # echo "${compile_cmd[@]}" && ${program_cmd[@]}
    # for item in "${compile_args[@]}"
    # do
    #     echo "compiler arg: [$item]"
    # done
    # for item in "${program_args[@]}"
    # do
    #     echo "prog arg: [$item]"
    # done
    # echo "compiler [$compiler]"
    # echo "compile_args [${compile_args[@]}]"
    if [ "$verbose" = true ]; then
        echo "$compiler" "${compile_args[@]} && $executable_name" "${program_args[@]}"
    fi
    "$compiler" "${compile_args[@]}" && "$executable_name" "${program_args[@]}"
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
		//#include <fmt/format.h>

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
    [ -z "$1" ] && echo 1>&2 "First argument must be directory" && return 1
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

function latest_download()
{
    find ~/Downloads/ -maxdepth 1 -type f -printf "%T@ %p\n" | \
        sort -rn -k1 | head -n 1 | sed -E "s/^[0-9]+\.[0-9]+ //"
}

# http://wiki.bash-hackers.org/syntax/pe
# This is the droid you're looking for
function droid()
{
    echo "http://wiki.bash-hackers.org/syntax/pe"
}

function set_mouse_keyboard_sens()
{
    # TODO: move these to udev scripts
    # Sets mouse sens
    # Regex matching mouse name to search for in output of xinput list
    # Possible todo is integrate with udev event thingys for automatic
    # replugging
    if command_exists xinput
    then
        local mice_name_regex="USB Mouse|Logitech G Pro Wireless Gaming Mouse|Logitech USB Receiver Mouse"
        local mouse_id="$(xinput list | grep "slave [ ]*pointer" | \
            sed -n -E "s/^.*($mice_name_regex) [[:space:]]*id=([0-9][0-9]*).*$/\2/p")"
        if [ -n "$mouse_id" ]
        then
            xinput --set-prop "$mouse_id" "libinput Accel Speed" -0.9
            xinput --set-prop "$mouse_id" "Coordinate Transformation Matrix" 1.8 0 0 0 1.8 0 0 0 2
        fi
    fi

    if command_exists xset
    then
        # Set keyboard delay and then repeat rate in milliseconds.
        # Set in i3 config
        xset r rate 220 40
        # echo "Setting mouse and keyboard sens"
    fi
}


# https://unix.stackexchange.com/a/391698/358344
# Inserts text into prompt! Pretty neat
function insert_with_delay()
{
    perl -le 'require "sys/ioctl.ph";
              $delay = shift @ARGV;
              unless(fork) {
                select undef, undef, undef, $delay;
                ioctl(STDIN, &TIOCSTI, $_) for split "", join " ", @ARGV;
              }' -- "$@";
}
export -f insert_with_delay

numb_cpus="$(grep -c ^processor /proc/cpuinfo)"

# Note this is in parentheses not braces so is run in subshell
# Note unsure if quoting and passing "$@" down through functions works as I
# expect currently
function build()
(
    cd build && cmake .. "$@" && cmake --build . --parallel "$numb_cpus"

    # Can add --parallel n # To cmake

    # rm -rf build && mkdir build
    # cd build && cmake ..
    # cmake --build build
    # cmake --build build --target test
    # # sudo cmake --build build --target install

    # cmake -S . -B build
    # cmake --install build
)

function after_build_insert_executable_on_line()
{
    # Find most recently modified executable file at the lowest depth
    executable="$(find build -maxdepth 2 -type f -executable -printf \
        "%d %T@ %p\n" | sort -r --key=1n,2n | head -n 1 | \
        sed -E "s/^[0-9]+ +[0-9]+\.[0-9]+ //")"
    insert_with_delay 0.16 "$executable"
}
export -f after_build_insert_executable_on_line

function m()
{
    if [ -x ".m.sh" ]
    then
        ./.m.sh "$@"
    else
        build "$@" && after_build_insert_executable_on_line
    fi
}

function mm()
{
    build "$@"
}

# alias m=""
# alias mm="build"

set -o vi

# linewrapping
#export TERM="xterm-256color"
export TERM="screen-256color"

# increase history line limit and file size limit
shopt -s histappend
export HISTFILESIZE=500000000
export HISTSIZE=25000000
# https://unix.stackexchange.com/a/49216/358344
# Commands prepended with a space will not be saved in history
export HISTCONTROL=ignorespace

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

alias ag="ag --ignore tags"

# no displaying hidden files when pressing tab
bind "set match-hidden-files off"

#complete -o default -W "$(cmd list-of-tabs)" cmd
alias json="python -mjson.tool"

export SHELL=/bin/bash

[ -f "$HOME/.dircolors" ] && eval "$(dircolors -b $HOME/.dircolors)"

# now git commits look soo pretty
# Set editor to nvim else vim else vi
editor=vi
command_exists vim && editor=vim
command_exists nvim && editor=nvim
export VISUAL="$editor"
export EDITOR="$editor"
alias nv="$EDITOR"

# disables default ctrl + S sending XOF pause
# allows use of it while reverse searching
# condition (bashism) checks for interactive session
# else get loads of stty ioctl errors
[[ $- == *i* ]] && stty -ixon

alias st="git status"

# trying for now, more powerful pattern matching
# eg ls !(dont_see_me*)
shopt -s extglob

# prettier git log using git lg
git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)' --abbrev-commit"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

if command_exists fd
then
    #let $FZF_DEFAULT_COMMAND = 'ag --hidden --ignore .git -l -g ""'
    excludes="-E *.git -E *.tmp -E *.so -E *.swp -E *.o -E *.obj -E *.pyc "
    excludes+="-E *.vim -E *.d -E ~.* -E *.d -E tags -E .clangd*"
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow $excludes "
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi


# https://github.com/junegunn/fzf/wiki/Examples#command-history
# re-wrote the script above
bind '"\C-r": "\C-x1\e^\er"'
bind -x '"\C-x1": __fzf_history';

# This allows in line replacements using Control-R
# Reminder
# Control-S toggles sorting
# Can use Tab and Shift Tab for multi select
# Few issues
# Sometimes we come out of this and press ESC to get into normal mode on cmd
# line and it refuses
# Also currently adds space that means if you run a cmd multiple times it keeps
# that on - could strip trailing whitespace, hmm
__fzf_history ()
{
    # __ehc "$(HISTTIMEFORMAT= history | \
    #     fzf +s --tac --tiebreak=index -m --toggle-sort=ctrl-r | \
    #     perl -ne 'm/^\s*([0-9]+)/ and print "!$1"')"
    __ehc "$(HISTTIMEFORMAT= history | \
        fzf --tac --tiebreak=index -m --toggle-sort=ctrl-r | \
        sed "s/^[[:space:]]*[0-9][0-9]*[[:space:]]\{2\}//")"
}

__ehc()
{
if
        [[ -n "$1" ]]
then
        bind '"\er": redraw-current-line'
        bind '"\e^": magic-space'
        READLINE_LINE=${READLINE_LINE:+${READLINE_LINE:0:READLINE_POINT}}${1}${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}
        READLINE_POINT=$(( READLINE_POINT + ${#1} ))
else
        bind '"\er":'
        bind '"\e^":'
fi
}


# https://stackoverflow.com/a/12179705
# Mind == blown. But what a great thing! Should convert some of these
# The only reason I'm hesitant to convert some of these is unsure if this would
# introduce unexpected behaviour with things like changing environment later? If
# running compile process from subshell etc.?

# I don't remember putting this line here. Think it was inserted by coc.nvim on
# install as it uses yarn as a package manager.

append_to_path "$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin"

# If interactive shell and login shell
# https://unix.stackexchange.com/a/50667
# if [[ $- == *i* ]] && shopt -q login_shell
# then
[[ $- == *i* ]] && set_mouse_keyboard_sens
# fi

alias make="make -j $numb_cpus"
if command_exists lscpu
then
    export CMAKE_BUILD_PARALLEL_LEVEL="$numb_cpus"
fi

# alias history to smart uniquified version if exists
# How the fook have I written this much bash and not known this about tilde
# expansion (or lack) in double quotes?
# https://unix.stackexchange.com/a/151865/358344
# ~/".local/bin/history.py" # <- Needs to look like this
function history()
{
    if [ "$#" -eq 0 ] && [ -f "$HOME/.local/bin/history.py" ] && \
        command_exists python3 && [ -z "$HISTTIMEFORMAT" ]
    then
        HISTTIMEFORMAT= builtin history | $HOME/.local/bin/history.py
    else
        builtin history "$@"
    fi
}
# if [ -f "$HOME/.local/bin/history.py" ] && command_exists python3
# then
#     alias history="HISTTIMEFORMAT= history | $HOME/.local/bin/history.py"
#     alias history="HISTTIMEFORMAT= history | $HOME/.local/bin/history.py"
# fi

mac="28:C6:3F:15:8C:3F"
alias bluetoothctl="sudo bluetoothctl"
alias hcitool="sudo hcitool"
alias btmgmt="sudo btmgmt"
alias gatttool="sudo gatttool"
alias wpa_cli="sudo wpa_cli"

# Asan doesn't work (presumably without resorting to discouraged -lasan flags)
# with just -fsanitize=address because for whatever reason on my Ubuntu system
# LD_PRELOAD is set to "libgtk3-nocsd.so.0" that seems to be related to this?
# https://github.com/lutris/lutris/issues/905
# https://packages.debian.org/stretch/libgtk3-nocsd0
# Easy seems to be to just set LD_PRELOAD=
export LD_PRELOAD=

export PATH="$PATH:$HOME/Qt/Tools/QtCreator/bin"
