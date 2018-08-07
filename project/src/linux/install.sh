#!/bin/bash
# Script will import docker image into system

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function check_image {
    if [[ "$(docker images -q $1 2> /dev/null)" != "" ]]; then
        read -r -p "Image with name $1 already exists. Do you want to remove this image? (y/n): " response
        echo
        if [[ $response =~ ^[Yy]$ ]]; then
            docker rmi -f $1
        fi
    fi
}

# get image path and import into to machine
echo "Importing docker image '@IMAGE_TAG@'"
check_image "@IMAGE_TAG@"
check_image "@IMAGE_TAG@:user"
IMAGE_PATH=$CWD/data/@IMAGE_NAME@
docker load < "$IMAGE_PATH"

# run configure on this image to personalise the image
echo "Modifying docker image '@IMAGE_TAG@'"
IMAGE_TAG="@IMAGE_TAG@"
IMAGE_TAG=${IMAGE_TAG#flow123d/}
export IMAGE_TAG=${IMAGE_TAG}

# no colors for Windows users for now
if [[ $(uname) == *"MINGW"* ]]; then
  export THEME=no-theme
else
  export THEME=dark
fi
echo "Using theme $THEME for the terminal"
"$CWD/bin/configure" --images "${IMAGE_TAG}" build

echo "--------------------------------------------"
if [ $? -eq 0 ]; then
    echo "Installation finished successfully"
    if [[ $(uname) == *"MINGW"* ]]; then
        echo "run Flow123d using file fterm.bat or flow123d.bat in bin folder"
    else
        echo "run Flow123d using script fterm.sh or flow123d.sh in bin folder"
    fi
else
    echo "Error during installation"
    exit 1
fi
