#!/bin/bash




mmv()
{
    if test $# -gt 0
    then
        # init vars
        declare -A new_name_dict

        get_input "$@"

        # move through keys and determine
        # correct course of action
        for old_name in "${!new_name_dict[@]}"
        do
            # get output name
            local dest="${new_name_dict[${old_name}]}"

            # function to handle dirs
            if [[ -n $dest ]]
            then
                conduct_mv $old_name $dest
            fi
        done
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




conduct_mv()
{
    local old=$1
    local new=$2


    # if new dir already exists
    if test -d $new
    then
        printf "Moving contents of ${old} to ${new}"

        mv ${old}* $new

    # if file already exists
    elif test -f $new
    then
        # check if dest is in queue
        if [[ -n ${new_name_dict[${old}]} ]]
        then
            new_name_dict=("${new_name_dict}/${new}")

            swap $old $new

        # else
        else
            warn
        fi

    else
        # make new dir and parents, mv
        create_path $new; mv $old $new
    fi
}





swap()
{
    # alias args
    local old=$1
    local new=$2

    # create temp file
    local tmp_space=$(mktemp -u mmv_XXXXXXX)

    # swap
    mv $old $tmp_space && mv $new $old && mv $tmp_space $new
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




warn()
{
    local path=$(readlink -f ${new})

    printf "\n\n\tCannot move \"${old}\" to \"${path}\"."
    printf "\n\t\"${path}\" is an existing file...\n"
}
