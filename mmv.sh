#!/bin/bash


################################################################################
# mmv main
#
# Globals:
#     - new_name_dict: associative array for holding key
#                      val pairs relating current names to new names
# Arguments:
#     - $@: all files and dirs to change names of
# Outputs:
#     - changes given files to new file names provided by user
# Returns:
#     - none
################################################################################
mmv()
{
    if test $# -gt 0
    then
        declare -A new_name_dict

        get_input "$@"

        conduct_renames

        conduct_mvs
    fi
}




################################################################################
# Gets new name input from user via $EDITOR
#
# Globals:
#     - none
# Arguments:
#     $@: all files to modify
# Outputs:
#     - out_names_arr: see create_name_dict()
# Returns:
#     - none
################################################################################
get_input()
{
    # create temp file to write in
    local temp_file
    temp_file=$(mktemp ~/.cache/mmv-XXXXX)

    # echo all arg names into temp file
    printf "%s\n" "$@" > "$temp_file"

    # open temp file in editor
    $EDITOR "$temp_file"

    # sanitize user input
    clean_input "$temp_file"

    # populate global associative array
    # containing key val pairs linking old
    # and new names
    create_name_dict "$temp_file" "$@"

    # delete temp file which was used
    # to gather new name args
    rm -f "$temp_file" 1> /dev/null
}





################################################################################
# sanitize user input given in text file
#
# Globals:
#     - none
# Arguments:
#     $1: in_file; file containing new file
#         names. Created by user in get_input()
# Outputs:
#     - sanitized user input in in_file
# Returns:
#     - none
################################################################################
clean_input()
{
    local in_file=$1
    local temp_file
    temp_file=$(mktemp ~/.cache/mmv-XXXXX)

    # expand any tildes in new names
    sed -i "s.~.${HOME}." "$in_file"

    # remove all newline chars so that
    # all vals, such as old names and
    # new names "line up" by index and
    # write to temp file
    awk NF "$in_file" > "$temp_file"

    # write temp file to out parameter
    mv "$temp_file" "$in_file"
}




################################################################################
# populates associative array, linking old
# names and new names
#
# Globals:
#     - creates none
#     - populates new_name_dict, init in mmv()
# Arguments:
#     $1: in_file; file containing new file
#         names. Created by user in get_input()
# Outputs:
#     - populated associative array
# Returns:
#     - none
################################################################################
create_name_dict()
{
    local i=0
    local -a out_names_arr
    local in_file=$1

    # read user-chosen new names into arr
    readarray -t out_names_arr < "$in_file"

    # loop through original names in arg list
    for old_name in "${@:2}"
    do
        # get current destination name/new name
        local dest=${out_names_arr[$i]}

        # if the old name does not match the
        # new name (meaning that the user
        # actually changed the name instead
        # of leaving it as is)
        if [[ $old_name != "$dest" ]]
        then

            # expand the path of the old name
            local expand_old
            expand_old=$(readlink -f "$old_name")

            # create associative array where
            # key = expanded old name and
            # val = new name
            new_name_dict[$expand_old]=$dest
        fi

        i=$((i+1))
    done
}




################################################################################
# loop through all entries in associative array of
# names and conduct any renames necessary because of
# collisions, i.e. new chosen names already exist in fs
#
# Globals:
#     - creates none
# Arguments:
#     - none
# Outputs:
#     - rename all files that will result in collision
#       with name provided as destination by user
# Returns:
#     - none
################################################################################
conduct_renames()
{
    # for all keys (old names) in global name dict
    for old_name in "${!new_name_dict[@]}"
    do
        # get associated val
        local dest=${new_name_dict[${old_name}]}

        # if destination is a directory
        if test -d "$dest"
        then

            # move all content from old dir into destination
            # WARNING: will overwrite dir contents!
            #          can change mv flags to protect them
            mv "${old_name}/*" "$dest"

            # remove dir
            rm --preserve-root -r "${old_name}" >> /dev/null

            # nullify in dict
            new_name_dict[$old_name]=""

        # if file already exists with destination name
        elif test -f "$dest"
        then
            # rename file with dest name to temp name
            rename_file "$dest"
        fi
    done
}




################################################################################
# rename individual item in fs to a temp name
# based on original name
#
# Globals:
#     - creates none
#     - uses new_name_dict
# Arguments:
#     $1: name_to_mv; a file in currently in fs
#         whose name is desired by a file to be
#         renamed by mmv
# Outputs:
#     - rename $1
# Returns:
#     - none
################################################################################
rename_file()
{
    local name_to_mv
    local to_mv_base
    local to_mv_dir

    # full path of $1
    name_to_mv=$(readlink -f "$1")

    # name of $1
    to_mv_base=$(basename "$name_to_mv")

    # path of $1 without name
    to_mv_dir=$(dirname "$name_to_mv")

    # create temp file
    tmp_name=$(mktemp -u "${to_mv_dir}"/mmv_XXXXX_"${to_mv_base}")

    echo "${tmp_name}"

    # mv arg item to temp name
    mv "$name_to_mv" "$tmp_name"

    # get destination, if it exists, of item in fs.
    # this will only produce a non-zero len str if
    # the item that we are renaming is also in the
    # arr of items to be moved. If the item that was
    # renamed is NOT in the array, it was simply an
    # item in the fs that had the same name as one that
    # the user provided to mmv as a destination
    local mv_name_dest=${new_name_dict[${name_to_mv}]}

    # if destination is a non-zero len str
    if [[ -n $mv_name_dest ]]
    then
        # nullify old entry
        new_name_dict[$name_to_mv]=""

        # create new entry with tmp name as key
        new_name_dict+=( [$tmp_name]=$mv_name_dest )
    fi

}




################################################################################
# loop through all entries in associative array
# and rename original items to their destination
# names
#
# Globals:
#     - creates none
#     - uses new_name_dict
# Arguments:
#     - none
# Outputs:
#     - rename all files to destination names
# Returns:
#     - none
################################################################################
conduct_mvs()
{
    # for all keys (old names) in global name dict
    for old_name in "${!new_name_dict[@]}"
    do
        # get associated val
        local dest=${new_name_dict[${old_name}]}

        # if the destination is a non-zero len str
        # (meaning that that the item has not been
        # deleted or renamed to a temp file in
        # rename_file())
        if [[ -n $dest ]]
        then
            # create any parent dirs and mv file to its destination
            mkdir -p "$(dirname "${dest}")"; mv "$old_name" "$dest"
        fi
    done
}
