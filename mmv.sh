#!/bin/bash


mmv()
{
    if test $# -gt 0
    then
        local i=0
        declare -A name_arr


        # create temp file
        # Note: I avoid /tmp, though I'd
        #       prefer it, so that I can
        #       avoid sudo during deletion
        temp_file=$(mktemp ~/.cache/mmv-XXXXXX)

        # echo all arg names into temp file
        printf "%s\n" "$@" > $temp_file

        $EDITOR $temp_file

        # put cleaned lines back into temp_file
        echo "$(awk NF $temp_file)" > $temp_file

        # read cleaned contents into arr
        readarray -t out_names_arr < "$temp_file"

        # delete temp file
        rm -f $temp_file 1> /dev/null


        # for all args in arg list
        for arg in "$@"
        do
            # create a temp file
            local cur_tmp="$(mktemp ./"$arg"-XXXXXX)"

            # rename current arg to temp file
            mv "$arg" "$cur_tmp"

            # create association in dictionary between
            # temp file and the name we want to change it to
            name_arr["$cur_tmp"]="${out_names_arr[$i]}"

            i=$((i+1))
        done


        # for key val pairs in dict
        for temp_name in "${!name_arr[@]}"
        do
            # change temp file name to desired name
            mv "$temp_name" "${name_arr[${temp_name}]}"
        done

    fi
}
