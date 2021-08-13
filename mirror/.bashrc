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

function get_realpath
{
    if command_exists realpath
    then
        realpath "$@"
    else
        echo "$(cd "$(dirname "$1")"; pwd -P)/$(basename "$1")";
    fi
}

function get_executable()
{
    # Find most recently modified executable file at the lowest depth
    # $1 is directory passed to find
    local executable="$(find "$1" -maxdepth 2 -type f \
        -executable -printf \
        "%d %T@ %p\n" | sort -r --key=1n,2n | head -n 1 | \
        sed -E "s/^[0-9]+ +[0-9]+\.[0-9]+ //")"
    echo "$executable"
}
export -f get_executable

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

function needle_regex_in_haystack_array()
{
    # Returns 0 if "$1" contains "$2" else 1
    # Pass array to function: https://askubuntu.com/a/995110
    local needle_regex="$1"
    shift
    # for arg; without "in" implicitly loops over elements list, awesome
    # See comments of https://stackoverflow.com/a/8574392/8594193
    for arg
    do
        # Unsure if need quotes on first arg in regex match here
        # The second arg is the regex, even if expanded from a variable, still
        # must be unquoted
        if [[ "$arg" =~ $needle_regex ]]; then
            return 0
        fi
    done
    return 1
}
export -f needle_regex_in_haystack_array

function ccc()
{
    # ccc test.cpp -stdlib=libc++ --ccc-verbose -Wl,-rpath,/usr/local/lib --ccc-clang++ --
    # Note to self about how to compile using libc++ rather than libstdc++

    # Urgh, installed boost myself on ubuntu 18.10 into /usr/local (include,
    # lib) then use time - get linker issues, urgh
    # Look into header only boost? Or shared (but then still need args I think)
    # ccc -O3 t.cpp -L/usr/local/lib -lboost_timer -lboost_chrono -Wl,-rpath=/usr/local/lib --
    # Hmm.. http://mywiki.wooledge.org/BashFAQ/050

    local compiler executable_name verbose=false compiler_search \
        print_compile_flags_only=false
    declare -a user_compiler_args program_args filenames \
        compiler_default_args_to_add compiler_args_to_remove
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
	--                  If argument "--" is present, args before it are passed to the
	                        compiler and those after to the program
	                        eg. ccc -std=c++17 -- program_arg1 program_arg2

	--ccc-verbose       Print additional info (eg. compile line)

	--ccc-compile-flags Print compile_flags.txt style options only
	                        Note: Prepends "-xc++" so clangd parses files (notably .h headers) as c++ not c

	--ccc-clang++       Use clang++ - may append ie. --ccc-clang++-9.0
	--ccc-g++           Use g++ - may append ie. --ccc-g++-8

	--ccc-no            Remove any compiler arguments matching this regex
	                      eg. --ccc-no-std=c++17
	                      eg. --ccc-no-fsanitize or "--ccc-no-fsanitize.*"
	                        (Careful with would-be wildcards if unquoted)
	                        which will both match -fsanitize=address,undefined

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


    # Fill user and compiler args from command line
    local end_of_user_compiler_args=false
    for arg in "$@"
    do
        if [ "$end_of_user_compiler_args" = true ]
        then
            program_args+=("$arg")
        else
            case "$arg" in
                --)
                    user_compiler_args=("${program_args[@]}")
                    program_args=()
                    end_of_user_compiler_args=true
                    ;;
                --ccc-g++*)
                    compiler_search="${arg#--ccc-}"
                    ;;
                --ccc-clang++*)
                    compiler_search="${arg#--ccc-}"
                    ;;
                --ccc-compile-flags)
                    print_compile_flags_only=true
                    ;;
                --ccc-verbose)
                    verbose=true
                    ;;
                --ccc-no*)
                    compiler_args_to_remove+=("${arg#--ccc-no}")
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
        fi
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
            echo >&2 "Could not find requested $compiler_search in PATH" && return 1
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

    if [ "$print_compile_flags_only" = false ] && [ -z "$compiler" ]
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


    if [ "$print_compile_flags_only" = false ]
    then
        # If no filenames to compile, error and quit
        [ "${#filenames[@]}" -eq 0 ] && echo_err "Could not find filename" \
            && return 1
        executable_name="${filenames[0]%.*}"
    fi


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
    if [ "$print_compile_flags_only" = false ]; then
        compiler_arg_defaults["-o"]="-o $executable_name"
    fi


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
                    #"-Wno-sign-conversion"
                    #"-Werror=shadow"
                    # "-Wshadow=compatible-local"
                    # "-Wduplicated-branches"
                    # "-Wduplicated-cond"
                    # "-Wlogical-op"
                    # "-Wuseless-cast"
    declare -a compiler_flags=(
                    "-Wall"
                    "-Wcast-align"
                    "-Wcast-qual"
                    "-Wconversion"
                    "-Wdisabled-optimization"
                    "-Wdouble-promotion"
                    # "-Weffc++"
                    "-Werror=return-type"
                    "-Wextra"
                    "-Wfloat-equal"
                    "-Wformat=2"
                    # "-Werror=shadow"
                    "-Wmissing-declarations"
                    "-Wmissing-include-dirs"
                    "-Wnull-dereference"
                    "-Wredundant-decls"
                    "-Wstrict-overflow=5"
                    "-Wswitch-default"
                    "-Wswitch-enum"
                    "-Wundef"
                    "-Wunreachable-code"
                    "-Wwrite-strings"

                    "-fdiagnostics-color"
                    "-fsanitize=address,undefined"
                    "-L/usr/local/lib"
                    "-Wl,-rpath,/usr/local/lib"
                    "-fverbose-asm"
                    "-g"
                    "-lfmt"
                    "-lstdc++fs"
                    "-pedantic"
                    "-pthread"
                    )


    # Actual cmds
    # Putting compiler flags at end for now so options like -lstdc++fs will work
    # Order matters: https://stackoverflow.com/a/409470/8594193
    declare -a compile_args compile_args_pre_remove=(
                    "${filenames[@]}"
                    "${compiler_default_args_to_add[@]}"
                    "${user_compiler_args[@]}"
                    "${compiler_flags[@]}"
                    )
    for arg in "${compile_args_pre_remove[@]}"
    do
        add=true
        # Add check to warn if not found
        for reg in "${compiler_args_to_remove[@]}"
        do
            if [[ "$arg" =~ $reg ]]; then
                add=false
                break
            fi
        done

        if [ "$add" = true ]
        then
            compile_args+=("$arg")
        fi
    done


    # Add warning if using google-benchmark and have left the sanitizers on as I
    # keep forgetting
    if needle_regex_in_haystack_array "^-fsanitize.*$" "${compile_args[@]}"
    then
        if needle_regex_in_haystack_array "^-O3$" "${compile_args[@]}"
        then
            echo_err "Warning/reminder from ccc: using -fsanitize with -O3"\
                "(add --ccc-no-fsanitize to remove)"
        fi
        if needle_regex_in_haystack_array "^-lbenchmark$" "${compile_args[@]}"
        then
            echo_err "Warning/reminder from ccc: using -fsanitize with -lbenchmark"\
                "(add --ccc-no-fsanitize to remove)"
        fi
        if needle_regex_in_haystack_array "^.*libbenchmark.*$" \
            "${compile_args[@]}"
        then
            echo_err "Warning/reminder from ccc: using -fsanitize with libbenchmark"\
                "(add --ccc-no-fsanitize to remove)"
        fi
    fi


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

    # # Set compile to lowest niceness
    # niceness="nice -n 19"

    if [ "$print_compile_flags_only" = true ]; then
        # Convenience for clangd compile_flags.txt to parse ".h" header files as
        # c++ and not c
        compile_args=( "-xc++" "${compile_args[@]}" )
        local IFS=$'\n'
        echo "${compile_args[*]}"
        return 0
    fi

    if [ "$verbose" = true ]; then
        echo "$compiler" "${compile_args[@]} && $executable_name" "${program_args[@]}"
    fi
    "$compiler" "${compile_args[@]}" && "$executable_name" "${program_args[@]}"
}
export -f ccc

function touch_cpp()
{
    : "${1?"Provide cpp filename"}"
    [ -f "$1" ] && echo_err "File with name $1 exists" && return 1

    # Assumes file spacing is 2 spaces
    local space="  "
    # Using <<- with the dash to disable leading tabs - see heredoc
    cat <<- EOF >> "$1"
		//#include "prettyprint.hpp"
		//#include <fmt/format.h>
		//#include <fmt/ranges.h>
		//#include <fmt/ostream.h>
		//#include <range/v3/all.hpp>

		#include <algorithm>
		#include <cassert>
		#include <iostream>
		#include <string>
		#include <vector>

		using namespace std::literals;

		int main(int /*argc*/, char** /*argv*/)
		{
		${space}std::cout << std::boolalpha;
		${space}std::cout << "Hello world!" << "\n";
		}
	EOF
}
export -f touch_cpp

function touch_hpp()
{
    # TODO: fix to get basename for guard if do "touch_hpp include/a.hpp"
    : "${1?"Provide hpp filename"}"
    [ -f "$1" ] && echo_err "File with name $1 exists" && return 1

    filename="$1"
    guard="${filename//./_}"    # Replace "." with "_"
    guard="${guard^^}"          # To uppercase

    # Assumes file spacing is 2 spaces
    local space="  "
    # Using <<- with the dash to disable leading tabs - see heredoc
    cat <<- EOF >> "$filename"
		#ifndef ${guard}
		#define ${guard}

		#endif // ${guard}
	EOF
}
export -f touch_hpp

function touch_cpp_hpp()
{
    default_hpp="hpp"
    default_cpp="cpp"
    help_text="Provide filename stem (without cpp or h etc. suffix)
        Optional 2nd arg is header file extension, default: \"${default_hpp}\"
        Optional 3rd arg is cpp file extension, default: \"${default_cpp}\""
    # This works with set -e, whereas '-z "$1"' doesn't
    if [ -z "${1+_}" ]
    then
        printf "$help_text\n"
        return 1
    fi
    header_file_extension="${2:-${default_hpp}}"
    cpp_file_extension="${3:-${default_cpp}}"

    hpp="$1.$default_hpp"
    cpp="$1.$default_cpp"

    [ -f "$hpp" ] && echo_err "Header file \"$hpp\" exists" && return 1
    [ -f "$cpp" ] && echo_err "Cpp file \"$cpp\" exists" && return 1
    touch_hpp "$hpp"
    touch_cpp "$cpp"
}
export -f touch_cpp_hpp

function touchpy3()
{
    : "${1?"Provide py filename"}"
    [ -f "$1" ] && echo_err "File with name $1 exists"

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
    executable="$(get_executable build)"
    # executable="$(find build -maxdepth 2 -type f -executable -printf \
        # "%d %T@ %p\n" | sort -r --key=1n,2n | head -n 1 | \
        # sed -E "s/^[0-9]+ +[0-9]+\.[0-9]+ //")"
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

function cm()
{
    if [ -x ".m.sh" ]
    then
        ./.m.sh "$@"
    else
        # Copied from function build for now
        (cd build && conan install -pr clang .. && cmake .. "$@" && \
            cmake --build . --parallel "$numb_cpus")
    fi
}

function b()
(
    cd build && cmake --build . --parallel "$numb_cpus" && cd .. && after_build_insert_executable_on_line
)

function mm()
{
    build "$@"
}

function gen_simple_cmake()
(
    # Generates a simple CMakeLists.txt
    # Call with no arguments to use current directory
    # Call with argument - to print to stdout
    # Call with directory argument to create a CMakeLists.txt in that dir

    set +eu
    # Quotes round EOF to avoid expanding heredoc variables
    local cmakelists_txt_contents
    read -r -d '' cmakelists_txt_contents <<- 'EOF'
	cmake_minimum_required(VERSION 3.16)
	project(test_project CXX)

	set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
	# set(CMAKE_VERBOSE_MAKEFILE ON)
	set(CMAKE_CXX_STANDARD 17)
	set(CMAKE_CXX_STANDARD_REQUIRED ON)
	set(CMAKE_CXX_EXTENSIONS OFF)

	find_package(package_name REQUIRED)

	add_executable(${PROJECT_NAME} main.cpp)
	target_link_libraries(${PROJECT_NAME} PUBLIC library_name::library_name)
	EOF
    if [ -z "$1" ]; then
        if ! [ -f CMakeLists.txt ]; then
            # I suppose technically could have race condition so safer to append
            echo "$cmakelists_txt_contents" >> CMakeLists.txt
        else
            echo_err "CMakeLists.txt in current directory exists"
            return 1
        fi
    elif [ "$1" == - ]; then
        echo "$cmakelists_txt_contents"
    elif [ -d "$1" ]; then
        # Cleaner way call this function again but error message needs to change
        if ! [ -f "$1"/CMakeLists.txt ]; then
            # I suppose technically could have race condition so safer to append
            echo "$cmakelists_txt_contents" >> "$1"/CMakeLists.txt
        else
            echo_err "CMakeLists.txt in $1 exists"
            return 1
        fi
    fi
)

function cmake_install_test()
(
    # Since this runs in a subshell we don't need to bother with the "local"
    # keyword

    my_name="cmake_install_test"

    set +eu
    read -r -d '' help_string <<- EOF

	Test that a CMake library installs as we would expect and that it can be
	consumed either via find_package or add_subdirectory.
	For example, let's test a CMake version of cxx-prettyprint (a header-only
	pretty printer for c++ standard library containers).
	Given that we have a CMakeLists.txt for cxx-prettyprint and the library files
	in the directory cxx-prettyprint.
	And we have a simple CMake test project in the directory prettyprint_test:
	  prettyprint_test
	    CMakeLists.txt
	        - containing roughly
	          project(test_cxx-prettyprint)
	          find_package(cxx-prettyprint)
	          # More CMake stuff (omitted)...
	          add_executable(\${PROJECT_NAME} main.cpp)
	          target_link_libraries(\${PROJECT_NAME} cxx-prettyprint::cxx-prettyprint)
	    main.cpp
	        - containing roughly
	          #include <iostream>
	          #include <vector>
	          #include "prettyprint.hpp"
	          int main() {
	            const std::vector<int> j{9};
	            std::cout << j << "\n";
	          }

	We run
	${my_name} -s /path/to/cxx-prettyprint -t /path/to/prettyprint_test

	This will build the library and install it to a temporary location inside
	--test_folder (a folder called cmake_test_[find_package_name] by default).
	It will then check whether the test project can build and consume the library
	via find_package, and then via add_subdirectory.
	It will also print the tree of the library install so you can check it looks
	correct.

	    -s|--source_package_dir)
	        Directory containing the CMakeLists.txt of the package we wish to test
	    -t|--test_package_dir)
	        Directory containing the CMakeLists.txt of a CMake project to test the
	        package can be consumed via find_package

	Optional:
	    -b|--build_folder|--test_folder)
	        Build directory where build folders will be created
	        Defaults to cmake_test_[find_package_name]
	    -c|--cmake_arguments)
	        Arguments to be passed to CMake
	        Eg. "-DCMAKE_BUILD_TYPE=Debug -DCMAKE_VERBOSE_MAKEFILE=ON"
	    -p|--find_package_name)
	        Name of the package in the CMake find_package([find_package_name]) call
	        Defaults to the string inside the source_package_dir's project() call
	    -e|--executable_name)
	        Executable name in the test_package to run to test the program
	        If unspecified, the most recently modified executable will be run that
	        was built
	    -h|--help)
	        Print help
	EOF

    if [ $# -eq 0 ]; then
        echo "$help_string"
        return 0
    fi

    source_package_dir=""
    test_package_dir=""

    # Folder name where all the build/test folders will be placed
    # Defaults to "cmake_test_$find_package_name"
    test_folder=""

    # Could split this into source build/package consumption cmake args if needed
    cmake_arguments="-DCMAKE_BUILD_TYPE=Debug"

    # find_package_name will be pulled from the project name in
    # $source_package_dir/CMakeLists.txt
    find_package_name=""

    # Will just execute most recently modified executable in build dir
    executable_name=""

    test_package_install_dir="test_package_install_dir"

    # We use "shift; shift" here instead of "shift 2"
    # as running "cmake_install_test -s" hangs with "shift 2" but correctly
    # errors out using "shift; shift"
    while [[ $# -gt 0 ]]
    do
        arg="$1"
        case "$arg" in
            -h|--help)
                echo "$help_string"
                return 0
                ;;
            -s|--source_package_dir)
                source_package_dir="$2"
                shift; shift
                ;;
            -t|--test_package_dir)
                test_package_dir="$2"
                shift; shift
                ;;
            -b|--build_folder|--test_folder)
                test_folder="$2"
                shift; shift
                ;;
            -c|--cmake_arguments)
                cmake_arguments="$2"
                shift; shift
                ;;
            -p|--find_package_name)
                find_package_name="$2"
                shift; shift
                ;;
            -e|--executable_name)
                executable_name="$2"
                shift; shift
                ;;
            *)
                echo_err "Unrecognised argument: $arg"
                return 1
                ;;
        esac
    done

    set -eu

    if [ -z "$source_package_dir" ]; then
        echo_err "source_package_dir may not be empty"
        return 1
    fi

    if [ -z "$test_package_dir" ]; then
        echo_err "test_package_dir may not be empty"
        return 1
    fi

    ### Don't edit below this line

    if [ "$EUID" -eq 0 ]
      then echo "Please don't run as root, it's scary..."
      return 1
    fi

    # Setup variables and remove old directories
    # source_package="$(get_realpath $source_package)"
    # Must be computed before "cd"ing to test_folder to get the right absolute path
    # template_cmake_dir="$(get_realpath $template_cmake_dir)"

    source_package_dir="$(get_realpath "$source_package_dir")"
    test_package_dir="$(get_realpath "$test_package_dir")"

    find_package_name="$(sed -n -E "s/^project\(([^ ]*).*$/\1/p" "$source_package_dir"/CMakeLists.txt)"

    if [ -z "$test_folder" ]; then
        test_folder="cmake_test_$find_package_name"
    fi

    mkdir -p "$test_folder"
    cd "$test_folder"

    # Make absolute
    test_folder="$(pwd)"

    # Must be computed after "cd"ing to test_folder to get the right absolute path
    test_package_install_dir="$(get_realpath test_package_install_dir)"

    mkdir -p "$test_package_install_dir"

    # Compile and install package
    mkdir -p build
    cd build
    cmake "$source_package_dir" $cmake_arguments \
        -DCMAKE_INSTALL_PREFIX="$test_package_install_dir"
    cmake --build .
    cmake --install .
    cd ..
    # ctest --progress .

    printf "\nInstalled package (what would be in /usr/local/)\n"
    tree "$test_package_install_dir"

    # Test find_package consumption of package
    printf "\nTest find_package version\n"
    mkdir -p build_find_package
    cd build_find_package
    cmake "$test_package_dir" $cmake_arguments \
        -DCMAKE_PREFIX_PATH="$test_package_install_dir"
    cmake --build .
    if [ -z "$executable_name" ]; then
        executable_name="$(get_executable .)"
    fi
    ./"$executable_name"
    cd ..

    # Test add_subdirectory consumption of package
    dst="$(get_realpath test_package_source)"
    echo "copying test_package_dir $test_package_dir to $dst excluding $test_folder"
    # return 0
    # Copy the test package source
    # rsync -a  "$test_package_dir" "$dst" --exclude "$d"
    # Trailing slash necessary to copy source contents and not source dir itself
    # The exclude is so if called via cmake_install_test -s .. -t . this won't
    # try and copy the test package directory into itself
    # Still recursive madness if the other way!
    rsync -aq "$test_package_dir/" "$dst" --exclude "$test_folder"
    cd test_package_source
    # Change find_package to add_subdirectory in CMakeLists.txt
    sed -E -i "s/(^.*find_package\($find_package_name.*)$/# \1\n# find_package substituted with add_subdirectory\nadd_subdirectory($find_package_name)/" CMakeLists.txt
    # Symlink back to the original package as if it was a subdirectory
    # ln -fs "$source_package_dir" "$find_package_name"
    cp -r "$source_package_dir" "$find_package_name"
    cd ..

    # Test add_subdirectory building of package
    printf "\nTest add_subdirectory version\n"
    mkdir -p build_add_subdirectory
    cd build_add_subdirectory
    cmake ../test_package_source $cmake_arguments
    cmake --build .
    ./"$executable_name"
    cd ..

)

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


# Colors
default=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)
purple=$(tput setaf 5)
orange=$(tput setaf 9)

# Less colors for man pages
export PAGER=less
# Begin blinking
export LESS_TERMCAP_mb=$red
# Begin bold
export LESS_TERMCAP_md=$orange
# End mode
export LESS_TERMCAP_me=$default
# End standout-mode
export LESS_TERMCAP_se=$default
# Begin standout-mode - info box
export LESS_TERMCAP_so=$purple
# End underline
export LESS_TERMCAP_ue=$default
# Begin underline
export LESS_TERMCAP_us=$green

# https://superuser.com/a/476874/976427
# https://askubuntu.com/a/897399
# Fix when accidentally TSTP by pressing control-z, find pid, then run
# kill -CONT with the pid to resume
# ps aux | awk '$8~/T/' # kill -CONT "pid"

# https://cmake.org/cmake/help/v3.17/envvar/CMAKE_EXPORT_COMPILE_COMMANDS.html
export CMAKE_EXPORT_COMPILE_COMMANDS=TRUE

# export PATH="/home/justin/emsdk:/home/justin/emsdk/upstream/emscripten:/home/justin/emsdk/node/12.18.1_64bit/bin:$PATH"

# Treesize for linux - https://unix.stackexchange.com/a/125451/358344
alias ncdu="ncdu -r --color dark"

# https://stackoverflow.com/a/9328525/8594193
function print_all_variables_cmake
{
    cat <<- 'EOF'
get_cmake_property(_variableNames VARIABLES)
list (SORT _variableNames)
foreach (_variableName ${_variableNames})
    message(STATUS "${_variableName}=${${_variableName}}")
endforeach()
EOF
}

#export PATH="$PATH:/home/justin/js/node-v12.19.0-linux-x64/bin"
