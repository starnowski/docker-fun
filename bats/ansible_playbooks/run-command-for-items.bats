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
    [ "$?" = "0" ]
    [ `grep 'Test 1 2 3' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_zero_output | wc -l ` == "1" ]
    [ `grep 'Finished test' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_zero_output | wc -l ` == "0" ]
    $BATS_TEST_DIRNAME/../../images/ansible_server/ansible_project/test/print_text_and_exit_zero.sh "Finished test" >> $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_zero_output
    [ "$?" = "0" ]
    [ `grep 'Test 1 2 3' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_zero_output | wc -l ` == "1" ]
    [ `grep 'Finished test' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_zero_output | wc -l ` == "1" ]

    # when
    run sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server /project/run-command-for-items.sh 'xx17:baba:let it go' '/project/test/print_text_and_exit_zero.sh "The item is $CURRENT_ITEM" >> /result_dir/first_test'

    echo "$output" >&3
    [ "$status" -eq "0" ]
    [ -e "$BATS_TMPDIR/$TIMESTAMP/first_test" ]
    echo "Test file output" >&3
    cat $BATS_TMPDIR/$TIMESTAMP/first_test >&3
    [ `grep 'xx17' $BATS_TMPDIR/$TIMESTAMP/first_test | wc -l ` == "1" ]
    [ `grep 'baba' $BATS_TMPDIR/$TIMESTAMP/first_test | wc -l ` == "1" ]
    [ `grep 'let it go' $BATS_TMPDIR/$TIMESTAMP/first_test | wc -l ` == "1" ]
}

function teardown {
    rm -rf $BATS_TMPDIR/$TIMESTAMP
    # Removing docker container for image "ansible_server"
    if [ "$STOP_DOCKER_CONTAINER_AFTER_TEST" = "true" ]; then
      sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ansible_server --format="{{.ID}}"))
    fi
}