#
# Usage:
# bats -rt .
#

function setup {
  export TIMESTAMP=`date +%s`

  echo "Build ansible docker image" >&3
  ANSIBLE_SERVER_DIR="$BATS_TEST_DIRNAME/../../images/ansible_server"

  # Build only image
   docker build -t ansible_server_2-3 $ANSIBLE_SERVER_DIR/ansible_2-3 >&3
}


@test "Should run container and print message that the executed container contains installed python in 2.7 version" {
    #when
    run  docker run --name ansible_server_bats_test --rm ansible_server_2-3  python2.7 -V

    #then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = 'Python 2.7.16' ]
}

@test "Should run container and print message that the executed container contains installed ansible in 2.3.3.0 version" {
    #when
    run  docker run --name ansible_server_bats_test --rm ansible_server_2-3  ansible --version

    #then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = 'ansible 2.3.3.0' ]
}

@test "Should run container and return exit code passed by executed ansible 'command' module" {
    #when
    run  docker run --name ansible_server_bats_test -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server_2-3 ansible-playbook -e command_to_run='ls' /project/run_command.yml -vvv

    #then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
}