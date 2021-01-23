#!/usr/bin/env bash

if [ $# -lt 4 ]
then
    echo "-p and -n flags are mandatory!"
    exit 1
elif [ $# -gt 4 ]
then
    echo "There are no other flags than -p and -n!"
    exit 1
else
    _local_path=""
    _file_name=""
    
    while getopts "p:n:" opt
    do
        case $opt in
            p) 
                _local_path="$OPTARG"
                ;;
            n)
                _file_name="$OPTARG"
                ;;
            *)
                echo "Wrong flag!"
                exit 1
                ;;
        esac
    done
    if [ "$_local_path" = "" ] || [ "$_file_name" = "" ]
    then
        echo "Wrong arguments!"
        exit 1
    fi
    cd "$_local_path"
    pwd
    echo "$_file_name"
    ffmpeg -y -i "$_file_name" -c:v libx264 -c:a aac -strict experimental -tune fastdecode -pix_fmt yuv420p -b:a 192k -ar 48000 "enc-${_file_name}"
    rm "$_file_name"
fi
exit 0
