#!/bin/sh

user=1000
prog="fieldworks-flex"
if [[ ! -z $1 ]]; then
    user=$1
fi
if [[ ! -z $2 ]]; then
    prog=$2
fi

if [[ $(id -u) -ne $user ]]; then
    echo "This script only works for user $user!"
    exit 1
fi

echo "echo Connectivity OK, FieldWorks Docker image already started." | nc localhost 3030
if [[ $? -ne 0 ]]; then
    docker run -d -p 3030:3030 -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix fieldworks:latest
    sleep 1
fi

echo $prog | nc localhost 3030
