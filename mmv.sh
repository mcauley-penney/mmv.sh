#!/bin/bash




mmv()
{
    if test $# -gt 0
    then
        # init vars
        declare -A new_name_dict

        get_input "$@"

        conduct_init_renames

        conduct_mvs
    fi
}




# Does:
#   1. creates temp file to edit in
#      Note: I avoid /tmp, though I'd
#            prefer it, so that I can
#            avoid sudo during
#            deletion at the end
#   2. opens file
#   3. cleans input
#   4. collects user input from file
#      into array
#   5. deletes temp file
get_input()
{
    # create temp file to write in
    local temp_file=$(mktemp ~/.cache/mmv-XXXXX)

    # echo all arg names into temp file
    printf "%s\n" "$@" > $temp_file

    $EDITOR $temp_file

    clean_input $temp_file

    create_name_dict "$temp_file" "$@"

    # delete temp editing file
    rm -f $temp_file 1> /dev/null
}




# Does:
#   1. expands any tildes into
#      the absolute path of $HOME
#   2. removes empty lines
clean_input()
{
    # expand tildes
    sed -i "s.~.${HOME}." $1

    # remove all newline chars
    echo "$(awk NF $1)" > $1
}




# Does:
#   1. creates array from user input
#      in file
#   2. loops through old names given
#      as CLI args
#       a. if old name does not match
#          the new name given as input
#           i. expand the path of the old
#              name
#           ii. assign old name as key, new
#               name as val in dict
create_name_dict()
{
    local i=0
    local -a out_names_arr
    local in_file=$1

    # read contents into arr
    readarray -t out_names_arr < "$in_file"

    # loop through original names in arg list
    for old_name in ${@:2}
    do
        # expand old name to abs path
        local dest=${out_names_arr[$i]}

        # compare old to new to determine
        # if we want to keep
        if [[ $old_name != $dest ]]
        then

            local expand_old=$(readlink -f $old_name)

            # create associative array where
            # key = old name, val = new name
            new_name_dict[$expand_old]=$dest
        fi

        i=$((i+1))
    done
}




conduct_mvs()
{
    for old_name in "${!new_name_dict[@]}"
    do
        local dest=${new_name_dict[${old_name}]}

        if [[ -n $dest ]]
        then
            create_path $dest; mv $old_name $dest
        fi
    done
}




conduct_init_renames()
{
    # change all names that conflict
    for old_name in "${!new_name_dict[@]}"
    do
        local dest=${new_name_dict[${old_name}]}

        if test -d $dest
        then
            # move all old contents
            #
            # TODO works but check for internal
            # renames, i.e. make sure you don't
            # overwrite file names that are the same
            #
            # may require changing structure for checking
            # if items already exist
            mv ${old_name}/* $dest

            # remove dir
            rm -r ${old_name}

            # nullify in dict
            new_name_dict[$old_name]=""

        # if file already exists
        elif test -f $dest
        then
            # rename file with dest name to temp name
            rename_file $dest
        fi
    done
}




consult_queue_for_conflicts()
{
    local name_to_check=$1
    local tmp_name=$2

    local mv_name_dest=${new_name_dict[${name_to_check}]}

    printf "Checking $name_to_check: dest=$mv_name_dest\n"

    # if the file that existed was in the queue to be moved
    if [[ -n $mv_name_dest ]]
    then
        # nullify old entry
        new_name_dict[$name_to_check]=""

        # create new entry with tmp name as key
        new_name_dict+=( [$tmp_name]=$mv_name_dest )
    fi
}




rename_file()
{
    # alias args
    local name_to_mv=$(readlink -f $1)

    # create temp file
    local tmp_name=$(mktemp -u mmv_XXXXX_$(basename $name_to_mv))

    mv $name_to_mv $tmp_name

    # check if name that was moved is inside of queue
    consult_queue_for_conflicts $name_to_mv $tmp_name
}




# create any needed dirs
create_path()
{
    local dir=$1

    # get path from absolute full path
    local path=$(dirname ${dir})

    # if desired path does not exist
    if test ! -d $path
    then
        mkdir -p $path
    fi
}
