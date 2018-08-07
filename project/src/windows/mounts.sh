#!/bin/bash
# Script will edit boot2docker loader
# to mount custom folders

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

local_inject=.inject.sh
local_bootlocal=.bootlocal.sh
boot2docker_bootlocal=/mnt/sda1/var/lib/boot2docker/bootlocal.sh
cat > $local_bootlocal << EOL
#!/bin/bash
# Script will mount custom directories

EOL

cat > $local_inject << EOL
#!/bin/bash
# Script will prepare env variable for extended mounts

EXTRA_MOUNT=""
EOL


function win2unix() {
    # takes a windows path string [a-Z]:\path\to\folder
    # and converts it to unix path 
    echo $1 | sed -e 's#^\([a-zA-Z]\):#\1#' -e 's#\\#/#g'
}

function write2bootlocal() {
    # writes mount commant to the local bootlocal file
    # first argument is windows path sencond is unix path
    windows=$1
    unix=$2
    cat >> $local_bootlocal << EOL
echo Mounting '$windows' -> '/$unix'
mkdir -p "/$unix"
mount -t vboxsf -o defaults,uid=\$(id -u docker),gid=\$(id -u docker) "$unix" "/$unix"
EOL
}

function write2inject() {
    # write variable edition to the inject file
    # first argument is windows path sencond is unix path
    windows=$1
    unix=$2
    cat >> $local_inject << EOL
echo "- $windows disk mounted to '/$unix'"
EXTRA_MOUNT="-v //$unix:/$unix \$EXTRA_MOUNT"
EOL
}

function CheckExec() {
    BIN=$1
    VAR=$2
    eval VAR_VALUE=\$${VAR}
    if [ -z "$VAR_VALUE" ]
    then 
      if [ -x "${BIN}" ]
      then
    	eval ${VAR}=\$BIN
      else
      	FULL_BIN=`which ${BIN} 2>/dev/null`
      	if [ -n "${FULL_BIN}" ] && [ -x "${FULL_BIN}" ]
      	then
      	  eval ${VAR}=\$BIN
      	fi
      fi	
    fi  
}

function ExecNotFound () {
    BIN=$1
    VAR=$2
    eval VAR_VALUE=\$${VAR}
    if [ -z "$VAR_VALUE" ]
    then 
      echo "Can not locate executable: $BIN"
      exit
    fi  	
}


# check location of VBoxManage
VBM="VBoxManage"
CheckExec "$VBM" VBOX_MANAGE
VBM="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
CheckExec "$VBM" VBOX_MANAGE
ExecNotFound "VBoxManage" VBOX_MANAGE

echo "VBM: $VBOX_MANAGE"

echo "All files and folders under $HOME are accessible."
echo "-------------------------------------------------"

addMount=1
changed=0
while [ $addMount -eq 1 ]
do
    read -r -p "Do you wish to add other mounts? [y/N] " response
    case $response in
        [yY][eE][sS]|[yY]) 
            
            # stop default machine
            if [[ $changed -eq 0 ]]; then
                echo "Stopping default to perform changes in virtual machine"
                docker-machine stop default >/dev/null 2>&1
                changed=1
            fi
            
            # prompt for location
            read -r -p "Enter letter of disk you want to mount (e.g. d): " windows
            windows="$windows:\\"
            unix=$(win2unix "$windows")
            echo "Mounting path '$windows' -> '/$unix'"
            
            # create this path in VBoxManage
            "$VBOX_MANAGE" sharedfolder add default --name "$unix" --hostpath "$windows" --automount
            
            # write mount commant to the local bootlocal file
            write2bootlocal "$windows" "$unix"
            
            # write variable edition to the inject file
            write2inject "$windows" "$unix"
            ;;
        *)
            addMount=0
            ;;
    esac
done


if [[ $changed -eq 1 ]]; then
    echo "Applying changes"
    docker-machine start default
    docker-machine ssh default sudo touch /$boot2docker_bootlocal
    docker-machine scp $local_bootlocal default:/$boot2docker_bootlocal
    docker-machine ssh default sudo chmod 777 /$boot2docker_bootlocal
    echo "export EXTRA_MOUNT=\$EXTRA_MOUNT" >> $local_inject
    chmod +x $local_inject
fi
