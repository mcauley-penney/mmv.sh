#!/bin/bash


mmv()
{
    # Process:
    #   arg -> temp var -> chosen name


    # if len of args > 0
    if test $# -gt 0
    then
        # init vars
        declare -a out_names_arr
        declare -A name_dict

        # get new names from user
        open_editor "$@"

        # declare -p out_names_arr
        # printf "\n"

        mk_name_dict "$@"

        mv_temp_files
    fi
}




open_editor()
{
    # create temp file
    #Note: I avoid /tmp, though I'd
    #      prefer it, so that I can
    #      avoid sudo during
    #      deletion at the end
    temp_file=$(mktemp ~/.cache/mmv-XXXXX)

    # echo all arg names into temp file
    printf "%s\n" "$@" > $temp_file

    $EDITOR $temp_file

    # remove all \n, put lines back
    echo "$(awk NF $temp_file)" > $temp_file

    # read contents into arr
    readarray -t out_names_arr < "$temp_file"

    # delete temp editing file
    rm -f $temp_file 1> /dev/null
}




mk_name_dict()
{
    local i=0

    # for all files that we want to change, create
    # a temp location and move the item of interest
    # to it. Then, use the temp file name as a key for
    # the value that we want to change it to
    for old_name in $@
    do
        local dest="${out_names_arr[$i]}"

        local dir_to_mk=$([[ "$dest" == *\/* ]] && echo $(dirname $dest) || echo '.')

        mkdir -p $dir_to_mk

        # create temp to get random name
        #   - easier than creating random str
        #
        # delete first so that, if src is
        # dir, dir won't be nested
        local tmp_dest=$(mktemp -u XXXXXXX_"$old_name")

        # rename current arg to temp file
        mv "$old_name" "$tmp_dest"

        # key = temp name, val = new name
        name_dict["$tmp_dest"]="${out_names_arr[$i]}"


        i=$((i+1))
    done
}




mv_temp_files()
{
    # for every key in dictionary
    for temp_name in "${!name_dict[@]}"
    do
        # change key/temp name to val/desired names
        mv "$temp_name" "${name_dict[${temp_name}]}"
    done
}
