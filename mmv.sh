#!/bin/bash

# TODO
#   1. exit if file isn't saved or edited
#   2. teach mk_temps to run only on command
#      instead of looping over all args
#       - intent: if a dir already exists, we
#                 can avoid making temps by just
#                 moving the src contents to the
#                 dest


mmv()
{
    if test $# -gt 0
    then

        # init vars
        declare -a out_names_arr
        declare -A name_dict


        open_editor "$@"

        mk_temps "$@"

        create_paths

        mv_temp_files
    fi
}




# create any needed dirs
create_paths()
{
    # loop through vals of name_dict
    for name in "${name_dict[@]}"
    do
        # get path from absolute full path
        local dir=$(dirname ${name})

        # if desired path does not exist
        if test ! -d $dir
        then
            mkdir -p $dir
        fi
    done
}




# open editor and populate out_names_arr
# with content from file
open_editor()
{
    # create temp file
    #Note: I avoid /tmp, though I'd
    #      prefer it, so that I can
    #      avoid sudo during
    #      deletion at the end

    # create temp file to write in
    temp_file=$(mktemp ~/.cache/mmv-XXXXX)

    # echo all arg names into temp file
    printf "%s\n" "$@" > $temp_file

    $EDITOR $temp_file

    # remove trailing slashes
    sed -i 's.\/$..' $temp_file

    sed -i "s.~.${HOME}." $temp_file

    # remove all \n, put lines back
    echo "$(awk NF $temp_file)" > $temp_file

    # read contents into arr
    readarray -t out_names_arr < "$temp_file"

    # delete temp editing file
    rm -f $temp_file 1> /dev/null
}




# TODO

# name_dict is populated with key, val pairs
# where the key is the temp name and the val
# is the name we desire
mk_temps()
{
    local i=0

    # for all files that we want to change, create
    # a temp location and move the item of interest
    # to it. Then, use the temp file name as a key for
    # the value that we want to change it to
    for old_name in $@
    do
        # create temp name using dry run
        #   - easier than creating random str
        local tmp_dest=$(mktemp -u XXXXXXX_"$old_name")

        # rename current arg to temp file
        mv "$old_name" "$tmp_dest"

        # key = temp name, val = new name
        name_dict["$tmp_dest"]="${out_names_arr[$i]}"
    done
}




# mv temp files to files
# of desired name
mv_temp_files()
{
    # loop through keys in name_dict
    for temp_name in "${!name_dict[@]}"
    do
        # get output name
        local dest="${name_dict[${temp_name}]}"


        if test -d $dest
        then
            mv ${temp_name}* $dest
            rm -r ${temp_name}

        else
            mv "$temp_name" "$dest"

        fi
    done
}
