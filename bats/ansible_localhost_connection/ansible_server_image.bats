#
# Usage:
# bats -rt .
#

function setup {
  export TIMESTAMP=`date +%s`

  echo "Build ansible docker image" >&3

  # Build only image
  sudo docker build -t ansible_server $BATS_TEST_DIRNAME/../../images/ansible_server >&3
}


@test "Should run container and print message that the executed container contains installed ansible in 2.8 version" {
    #when
    run sudo docker run --name ansible_server_bats_test --rm ansible_server  ansible --version

    #then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = 'ansible 2.8.1' ]
}



