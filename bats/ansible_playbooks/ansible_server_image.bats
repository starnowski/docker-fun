#
# Usage:
# bats -rt .
#

function setup {
  export TIMESTAMP=`date +%s`

  echo "Build ansible docker image" >&3
  ANSIBLE_SERVER_DIR="$BATS_TEST_DIRNAME/../../images/ansible_server"

  # Build only image
  sudo docker build -t ansible_server $ANSIBLE_SERVER_DIR >&3
}

@test "Should create script with passed command" {
    # given
    #docker build -t ansible_server $ANSIBLE_SERVER_DIR >&3
    
    #when
    sudo docker run --name ansible_server_bats_test --rm ansible_server  ansible-playbook -e '_command="exit 7"' -e "_script_path=/project/tmp_script.sh" /project/run_shell_on_localhost.yml -vvv
    run sudo docker run --name ansible_server_bats_test --rm ansible_server  cat /project/tmp_script.sh

    #then
    echo "output is --> $output <--"  >&3
    [ "${lines[0]}" = '#!/bin/bash' ]
    [ "${lines[1]}" = 'set -e' ]
    [ "${lines[2]}" = 'exit 7' ]
}


