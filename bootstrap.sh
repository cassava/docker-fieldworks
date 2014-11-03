#!/bin/sh
#
# Automate building the fieldworks image.

name="fieldworks"
version=8.1.1
release=9
tag="${version}-${release}"

display=$DISPLAY
if [[ -z $display ]]; then
    display=":0.0"
fi

home=$HOME
function get_home() {
    read -r -p "Home directory [${home}]: " home
    if [[ -z ${home} ]]; then
        home=$HOME
    elif [[ ! -d ${home} ]]; then
        echo "Error: directory ${home} does not exist!"
        exit 1
    fi
}

user_id=$(id -u)
group_id=$(id -g)
function get_user_id() {
    read -r -p "User ID [${user_id}]: " user_id
    if [[ -z ${user_id} ]]; then
        user_id=$(id -u)
    fi
    group_id=$(id -g ${user_id})
}

image_id=
function get_image_id() {
    image_id=$(docker images | awk -vname=${name} -vtag="${tag}" '{ if ($1 == name && $2 == tag) print $3 }')
    test ! -z ${image_id}
    return $?
}

container_id=
function get_container_id() {
    container_id=$(docker ps -a | awk -vnametag="${name}:${tag}" '{ if ($2 == nametag) print $1 }')
    test ! -z ${container_id}
    return $?
}

function build_image() {
    echo "Using user ID ${user_id} and home directory ${home}."
    sed -re "s/(.*useradd.*-u *)[0-9]+(.*)/\1${user_id}\2/" -i Dockerfile
    if [[ $use_cache -eq 0 ]]; then
        docker build --no-cache -t "${name}:${tag}" .
    else
        docker build -t "${name}:${tag}" .
    fi
    get_image_id
    docker tag ${image_id} "${name}:latest"
}

function create_container() {
    docker create -p 2020:22 -e DISPLAY=${display} -v /tmp/.X11-unix:/tmp/.X11-unix -v ${home}:/home/you "${name}:${tag}"
}

function get_container_id() {
    container_id=$(docker ps -a | awk -vnametag="${name}:${tag}" '{ if ($2 == nametag) print $1 }')
    test ! -z ${container_id}
    return $?
}

function start_container() {
    local id=$1
    docker ps | grep ${id}
    if [[ $? -ne 0 ]]; then
        docker start ${id}
    fi
}

use_cache=0
if [[ $1 == "--use-cache" ]]; then
    use_cache=1
fi

echo "Fieldworks in Docker Setup"
echo ""
echo "You'll need to answer a few questions before we can get started."

get_home
get_user_id

# Make sure that the image is created.
echo -n "Checking for image tagged with ${name}:${tag}... "
if get_image_id; then
    echo "success."
else
    echo "failed."
    echo "Building image ${name}:${tag}..."
    build_image
    get_image_id
fi

# Check if a container is started yet.
echo -n "Checking for started container tagged with ${name}:${tag}... "
if get_container_id; then
    echo "success."
else
    echo "failed."
    echo "Creating container ${name}:${tag}..."
    create_container
    get_container_id
fi

start_container ${container_id}

echo "Installing desktop entries..."
desktop_dest=${home}/.local/share/applications
autostart_dest=${home}/.config/autostart
install -m644 -o${user_id} -g${group_id} fieldworks-flex.desktop fieldworks-te.desktop ${desktop_dest}/
install -m644 -o${user_id} -g${group_id} docker-fieldworks.desktop ${autostart_dest}/
sed -e "s/{{container_id}}/${container_id}/" -i "${desktop_dest}/fieldworks-flex.desktop" "${desktop_dest}/fieldworks-te.desktop"
sed -e "s/{{container_id}}/${container_id}/" -i "${autostart_dest}/docker-fieldworks.desktop"

echo "All done!"
exit 0
