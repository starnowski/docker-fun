#
# Usage:
# bats -rt .
#

function setup {
  export TIMESTAMP=`date +%s`

  echo "Build ansible docker image" >&3
  ANSIBLE_SERVER_DIR="$BATS_TEST_DIRNAME/../../images/ansible_server/ansible_2-3"

  # Build only image
  sudo docker build -t ansible_server_2-3 $ANSIBLE_SERVER_DIR >&3
}


@test "Should run container and print message that the executed container contains installed python in 2.7 version" {
    #when
    run sudo docker run --name ansible_server_bats_test --rm ansible_server_2-3  python2.7 -V

    #then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = 'Python 2.7.16' ]
}

