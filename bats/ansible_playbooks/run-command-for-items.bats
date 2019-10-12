#
# Usage:
# bats -rt .
#

function setup {
  export TIMESTAMP=`date +%s`

  echo "Build ansible docker image" >&3
  ANSIBLE_SERVER_DIR="$BATS_TEST_DIRNAME/../../images/ansible_server"

  if [ "$ANSIBLE_SERVER_IMAGE_CREATED" = "true" ]; then
    echo "Skipping image building" >&3
  else
    # Build only image
    $BATS_TEST_DIRNAME/build_ansible_server_image.sh $ANSIBLE_SERVER_DIR >&3
  fi
  mkdir -p $BATS_TMPDIR/$TIMESTAMP
  export STOP_DOCKER_CONTAINER_AFTER_TEST=
}

@test "should execute command for each item and returns exit code zero if execution for each item will succeed" {
    # given
    $BATS_TEST_DIRNAME/../../images/ansible_server/ansible_project/test/print_text_and_exit_zero.sh "Test 1 2 3" > $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_zero_output
    [ `grep 'Test 1 2 3' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_zero_output | wc -l ` == "1" ]
    #$BATS_TEST_DIRNAME/../../ansible_project/test/print_text_and_exit_zero.sh "Finished test" >> $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_zero_output

    # when
    # sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server  ansible-playbook -e '_command="exit 7"' -e "_script_path=/result_dir/tmp_script.sh" /project/create_shell_script_on_localhost.yml -vvv

}

function teardown {
    rm -rf $BATS_TMPDIR/$TIMESTAMP
    # Removing docker container for image "ansible_server"
    if [ "$STOP_DOCKER_CONTAINER_AFTER_TEST" = "true" ]; then
      sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ansible_server --format="{{.ID}}"))
    fi
}