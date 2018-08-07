#!/bin/bash
# Script will start docker

CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# run docker shell within current dirrectory
echo "- Home directory mounted to '$HOME'"
if [ -f "$CWD/.inject.sh" ]; then
    source "$CWD/.inject.sh"
fi


# if no argument was supplied open shell
if [ -z "$1" ]
  then
    docker run -ti --rm -v "/$HOME:/$HOME" $EXTRA_MOUNT -w "/$(pwd)" "@IMAGE_TAG@:user" bash -l
else
    echo "Executing $@"
    if [[ "$1" == "--" ]]; then
      # special case for GeoMop application
      # fterm.sh -- -di /foo/bar
      FLAGS=$2
      WORKDIR=$3
      shift; shift; shift
      docker run $FLAGS -v "/$HOME:/$HOME" $EXTRA_MOUNT -w "/$WORKDIR" "@IMAGE_TAG@:user" "$@"
      exit 0
    else
      docker run -ti --rm -v "/$HOME:/$HOME" $EXTRA_MOUNT -w "/$(pwd)" "@IMAGE_TAG@:user" "$@"
    fi
fi

# check exit code
# if we detect error, we exit console
# only after user preses enter (user thus can see error messages or output)
RC=$?
if [ $RC -ne 0 ]; then
    echo -e "\n\n\n"
    echo "Command failed (exit code: $RC)"
    read -p "Press enter to exit"
fi
