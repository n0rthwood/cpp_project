#!/bin/bash

# Remote development helper script
CONFIG_FILE=".dev_config.yaml"

# Function to read values from yaml file
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

# Load configuration
eval $(parse_yaml $CONFIG_FILE)

# SSH command prefix
SSH_CMD="ssh ${remote_server_user}@${remote_server_host}"
REMOTE_WORKSPACE="${remote_server_workspace}"

function sync_to_remote {
    echo "Syncing local files to remote..."
    rsync -avz --exclude '.git' --exclude 'build' --exclude '.dev_config.yaml' \
        ./ ${remote_server_user}@${remote_server_host}:${REMOTE_WORKSPACE}/cpp_project/
}

function build_on_remote {
    echo "Building project on remote..."
    $SSH_CMD "cd ${REMOTE_WORKSPACE}/cpp_project && ./build.sh"
}

function run_tests_on_remote {
    echo "Running tests on remote..."
    $SSH_CMD "cd ${REMOTE_WORKSPACE}/cpp_project && ./build/bin/test_core"
}

function test_python_ext {
    echo "Testing Python extension on remote..."
    $SSH_CMD "cd ${REMOTE_WORKSPACE}/cpp_project && python3 -c 'import py_core_lib; print(\"Python extension loaded successfully\")'"
}

case "$1" in
    "sync")
        sync_to_remote
        ;;
    "build")
        build_on_remote
        ;;
    "test")
        run_tests_on_remote
        ;;
    "python")
        test_python_ext
        ;;
    "all")
        sync_to_remote
        build_on_remote
        run_tests_on_remote
        test_python_ext
        ;;
    *)
        echo "Usage: $0 {sync|build|test|python|all}"
        exit 1
        ;;
esac
