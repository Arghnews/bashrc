#!/usr/bin/env bash

set -e -o pipefail

# TODO: bin the items file, just mirror the source directory, use find etc. to
# get it all into array
# set -x

function error()
{
    # Using printf so can send in \n in strings
    printf >&2 "$@\n"
    exit 1
}

function echo_e()
{
    # This function is highly limited in what it can do, feels brittle really,
    # according to a bash FAQ page article 50
    [ -z ${dry_run+x} ] && error "Dry run var unset"
    if [ "$dry_run" = true ]; then echo "$@"
    else echo "$@" && "$@"; fi
}

function strip_trailing_slashes()
{
    sed "s:\([^/]\)/*$:\1:" <<< "$1"
}

function make_backup_name()
{
    # Strips trailing slashes, preserving path "/" (not sure we care but eh)
    local path="$(strip_trailing_slashes "$1")"
    while [ -e "$path" ]
    do
        path+="~"
    done
    echo "$path"
}

function dir_relative_to_absolute_path()
{
    [ -d "$1" ] || error "Directory does not exist: $1"
    echo "$(cd "$1" && pwd)"
}

# @param directory_from Directory in which to place the symlink
# @param target Other arguments to pass to ln, including link target
# This function respects dry_run as much as it can
# Problem is it may depend on dirs that MUST have been created in an actual run
function make_link()
{
    [ -n "$1" ] && [ -n "$2" ] || error "Function requires at least 2 arguments"
    local directory_from="$1"
    shift
    if [ "$dry_run" = false ]
    then
        [ -d "$directory_from" ] || error "Directory does not exist: $1"
    fi
    echo_e cd "$directory_from"
    echo_e ln -vs "$@"
    echo_e cd -
}

function main()
{
    command -v "readlink" &>/dev/null || error "Requires readlink"

    # These MUST NOT be local variables, functions depend on them (they are
    # effectively globals)
    dry_run=false
    verbose=false

    # mirror="mirror"
    # dst="/home/justin/bashrc/test_home"

    # Heredoc MUST be indented by actual tabs
    read -r -d '' help_string <<- EOF || :
	TL;DR:
	# See what would happen
	# ./mirror.sh -s mirror -d ~ -i mirror.txt -n
	# Make new links
	# ./mirror.sh -s mirror -d ~ -i mirror.txt

	This script is designed for creation and updating of various config symlinks
	from one central git repo (the source directory, --src) to respective
	dotfiles such as ".vimrc".

	For example running
	./mirror.sh --src mirror --dst /home/me -i <(echo .vim/plugged)
	creates a symlink at /home/me/.vim/plugged to mirror/.vim/plugged

	If a symlink already exists that points to the correct location, nothing
	happens.

	Otherwise if a symlink, file or directory exist at the location they will
	be renamed (backed up) with an extension and the correct symlink created.

	-n, --dry-run           Just print what would be done
	-s, --src               Directory tree from which to mirror (source)
	-d, --dst               Home directory that will be populated with symlinks
	-i, --items-file        File with one entry per line of files/dirs that
                                will be linked to. Each entry MUST be a relative
                                path, relative to --src. Blank lines and lines
                                starting with '#' will be ignored.
	-v, --verbose           Increases verbosity
	EOF

    [ "$#" -eq 0 ] && echo "$help_string" && return 1

    # for arg in "$@" # Shift doesn't work with this
    while [[ $# -gt 0 ]]
    do
        case "$1" in
            -h|--h|-help|--help)
                echo "$help_string"
                return 0
                ;;
            -n|--dry-run)
                dry_run=true
                shift
                ;;
            -s|--src)
                src_home="$2"
                shift 2
                ;;
            -d|--dst)
                dst_home="$2"
                shift 2
                ;;
            -i|--items_file)
                items_file="$2"
                shift 2
                ;;
            -v|--verbosity)
                verbose=true
                shift
                ;;
            *)
                error "Unrecognised argument: $1\n$help_string"
                ;;
        esac
    done

    [ -d "$src_home" ] || error "src directory must exist"
    [ -d "$dst_home" ] || error "dst directory must exist"
    [ -f "$items_file" ] || error "items file must exist"

    declare -a items
    # https://stackoverflow.com/a/10929511/8594193
    while IFS= read -r line
    do
        # Always another exception/rule - lack of quotes is deliberate in if
        # https://stackoverflow.com/a/18710850/8594193
        # Ignore blank lines or those that start with #
        if [[ $line =~ ^# || -z "$line" ]]
        then
            continue
        fi
        items+=("$line")
    done < "$items_file"

    # Home dir to copy from (to make mirror of)
    src_home="$(dir_relative_to_absolute_path "$src_home")"

    # Home dir to copy into
    dst_home="$(dir_relative_to_absolute_path "$dst_home")"

    for item_rela_path in "${items[@]}"
    do
        # item_rela_path="" # Relative path from src_home to item
        src_item="$src_home/$item_rela_path"
        dst_item="$dst_home/$item_rela_path"
        dst_dir_item="${dst_item%/*}" # Dst dir of item
        item_basename="${item_rela_path##*/}" # Name of item

        echo "Trying to link $dst_item to $src_item"

        # Do not quote mkdir_cmd
        if [ "$verbose" = true ]
        then
            echo_e mkdir -pv "$dst_dir_item"
        else
            mkdir -p "$dst_dir_item"
        fi

        if ! [ -e "$dst_item" ]
        then
            echo "Item does not exist, making link"
            make_link "$dst_dir_item" "$src_item"
        else
            # echo "Item with same name exists"
            # -f or -d will return true on symlinks pointing to files or dirs
            # respectively so ensure that -L test is BEFORE -f or -d test
            if [ -L "$dst_item" ]
            then
                existing_link_dst="$(readlink -f "$dst_item")"
                if [ "$existing_link_dst" = "$src_item" ]
                then
                    printf "Item is symlink that already points to right place"
                    echo    ", no action needed"
                else
                    printf "Item is symlink, making backup of existing symlink "
                    echo "and making symlink"
                    make_link "$dst_dir_item" --backup=numbered "$src_item"
                fi
            elif [ -f "$dst_item" ] || [ -d "$dst_item" ]
            then
                printf "Item with same name exists and is file or directory, "
                echo "making backup and then making symlink"
                backup_name="$(make_backup_name "$dst_item")"
                echo_e mv -vT "$dst_item" "$backup_name"
                make_link "$dst_dir_item" "$src_item"
            else
                error "Unrecognised file type: $dst_item"
            fi

        fi

    echo ""

    done
}

main "$@"
