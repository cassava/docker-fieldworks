#!/bin/sh

user=1002
prog="fieldworks-flex"
if [[ ! -z $1 ]]; then
    prog=$1 
fi

if [[ $(id -u) -ne $user ]]; then
    echo "This script only works for user $user!"
    exit 1
fi

echo "echo Checking connectivity." | nc localhost 3030
if [[ $? -ne 0 ]]; then
    docker run --rm -p 3030:3030 -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME:/home/you fieldworks:latest
fi

echo $prog | nc localhost 3030
