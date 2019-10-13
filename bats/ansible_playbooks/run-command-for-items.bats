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

@test "[run-command-for-items] should execute command for each item and returns exit code zero if execution for each item will succeed" {
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

@test "[run-command-for-items] should execute command for each item and returns exit code non zero when execution for the first command will failed" {
    # given
    $BATS_TEST_DIRNAME/../../images/ansible_server/ansible_project/test/print_text_and_exit_non_zero.sh "Fail 76" "Fail 76" > $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output || script_failed="true"
    [ "$script_failed" == "true" ]
    [ `grep 'Script failed: Fail 76' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output | wc -l ` == "1" ]
    [ `grep 'Script failed: Finished failing test' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output | wc -l ` == "0" ]
    [ `grep 'Script succeeded: Script should not fail' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output | wc -l ` == "0" ]

    $BATS_TEST_DIRNAME/../../images/ansible_server/ansible_project/test/print_text_and_exit_non_zero.sh "Finished failing test" "Finished failing test" >> $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output || script_failed="true"
    [ "$script_failed" == "true" ]
    [ `grep 'Script failed: Fail 76' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output | wc -l ` == "1" ]
    [ `grep 'Script failed: Finished failing test' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output | wc -l ` == "1" ]
    [ `grep 'Script succeeded: Script should not fail' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output | wc -l ` == "0" ]

    $BATS_TEST_DIRNAME/../../images/ansible_server/ansible_project/test/print_text_and_exit_non_zero.sh "Script should not fail" "xxxxx" >> $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output
    [ `grep 'Script failed: Fail 76' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output | wc -l ` == "1" ]
    [ `grep 'Script failed: Finished failing test' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output | wc -l ` == "1" ]
    [ `grep 'Script succeeded: Script should not fail' $BATS_TMPDIR/$TIMESTAMP/test_print_text_and_exit_non_zero_output | wc -l ` == "1" ]

    # when
    run sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server /project/run-command-for-items.sh 'aaa:bbb:zzz' '/project/test/print_text_and_exit_non_zero.sh "$CURRENT_ITEM" aaa >> /result_dir/second_test'

    echo "$output" >&3
    [ "$status" -ne "0" ]
    [ -e "$BATS_TMPDIR/$TIMESTAMP/second_test" ]
    echo "Test file output" >&3
    cat $BATS_TMPDIR/$TIMESTAMP/second_test >&3
    [ `grep 'Script failed: aaa' $BATS_TMPDIR/$TIMESTAMP/second_test | wc -l ` == "1" ]
    [ `grep 'Script succeeded: bbb' $BATS_TMPDIR/$TIMESTAMP/second_test | wc -l ` == "1" ]
    [ `grep 'Script succeeded: zzz' $BATS_TMPDIR/$TIMESTAMP/second_test | wc -l ` == "1" ]
}

@test "[run-command-for-items] should execute command for each item and returns exit code non zero when execution for middle command will failed" {

    # when
    run sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server /project/run-command-for-items.sh 'aaa:bbb:zzz' '/project/test/print_text_and_exit_non_zero.sh "$CURRENT_ITEM" bbb >> /result_dir/second_test'

    echo "$output" >&3
    [ "$status" -ne "0" ]
    [ -e "$BATS_TMPDIR/$TIMESTAMP/second_test" ]
    echo "Test file output" >&3
    cat $BATS_TMPDIR/$TIMESTAMP/second_test >&3
    [ `grep 'Script succeeded: aaa' $BATS_TMPDIR/$TIMESTAMP/second_test | wc -l ` == "1" ]
    [ `grep 'Script failed: bbb' $BATS_TMPDIR/$TIMESTAMP/second_test | wc -l ` == "1" ]
    [ `grep 'Script succeeded: zzz' $BATS_TMPDIR/$TIMESTAMP/second_test | wc -l ` == "1" ]
}

@test "[run-command-for-items] should execute command for each item and returns exit code non zero when execution for the last command will failed" {

    # when
    run sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server /project/run-command-for-items.sh 'aaa:bbb:zzz' '/project/test/print_text_and_exit_non_zero.sh "$CURRENT_ITEM" zzz >> /result_dir/second_test'

    echo "$output" >&3
    [ "$status" -ne "0" ]
    [ -e "$BATS_TMPDIR/$TIMESTAMP/second_test" ]
    echo "Test file output" >&3
    cat $BATS_TMPDIR/$TIMESTAMP/second_test >&3
    [ `grep 'Script succeeded: aaa' $BATS_TMPDIR/$TIMESTAMP/second_test | wc -l ` == "1" ]
    [ `grep 'Script succeeded: bbb' $BATS_TMPDIR/$TIMESTAMP/second_test | wc -l ` == "1" ]
    [ `grep 'Script failed: zzz' $BATS_TMPDIR/$TIMESTAMP/second_test | wc -l ` == "1" ]
}

@test "[run-command-for-items] should execute command for each item in base directory" {
    # when
    run sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server /project/run-command-for-items.sh 'aaa:bbb:zzz' 'echo "$CURRENT_ITEM: start path $(pwd)" | tee -a /result_dir/base_dir_test && cd /project/test && echo "$CURRENT_ITEM: end path $(pwd)" | tee -a /result_dir/base_dir_test'

    echo "$output" >&3
    [ "$status" -eq "0" ]
    [ -e "$BATS_TMPDIR/$TIMESTAMP/base_dir_test" ]
    echo "Test file output" >&3
    cat $BATS_TMPDIR/$TIMESTAMP/base_dir_test >&3
    [ `grep 'aaa: start path /project' $BATS_TMPDIR/$TIMESTAMP/base_dir_test | wc -l ` == "1" ]
    [ `grep 'aaa: end path /project/test' $BATS_TMPDIR/$TIMESTAMP/base_dir_test | wc -l ` == "1" ]
    [ `grep 'bbb: start path /project' $BATS_TMPDIR/$TIMESTAMP/base_dir_test | wc -l ` == "1" ]
    [ `grep 'bbb: end path /project/test' $BATS_TMPDIR/$TIMESTAMP/base_dir_test | wc -l ` == "1" ]
    [ `grep 'zzz: start path /project' $BATS_TMPDIR/$TIMESTAMP/base_dir_test | wc -l ` == "1" ]
    [ `grep 'zzz: end path /project/test' $BATS_TMPDIR/$TIMESTAMP/base_dir_test | wc -l ` == "1" ]
}

@test "[run-command-for-items] should execute command for each item in new sub shell so that no variable setted by previous execution would be available for next command execution" {
    # when
    run sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server /project/run-command-for-items.sh 'aaa:bbb' 'echo "START: item $CURRENT_ITEM: test value -->$TEST_VALUE<--" | tee -a /result_dir/sub_shell_test && export TEST_VALUE=$CURRENT_ITEM && echo "END: item $CURRENT_ITEM: test value -->$TEST_VALUE<--" | tee -a /result_dir/sub_shell_test'

    echo "$output" >&3
    [ "$status" -eq "0" ]
    [ -e "$BATS_TMPDIR/$TIMESTAMP/sub_shell_test" ]
    echo "Test file output" >&3
    cat $BATS_TMPDIR/$TIMESTAMP/sub_shell_test >&3
    [ `grep 'START: item aaa: test value --><--' $BATS_TMPDIR/$TIMESTAMP/sub_shell_test | wc -l ` == "1" ]
    [ `grep 'END: item aaa: test value -->aaa<--' $BATS_TMPDIR/$TIMESTAMP/sub_shell_test | wc -l ` == "1" ]
    [ `grep 'START: item bbb: test value --><--' $BATS_TMPDIR/$TIMESTAMP/sub_shell_test | wc -l ` == "1" ]
    [ `grep 'END: item bbb: test value -->bbb<--' $BATS_TMPDIR/$TIMESTAMP/sub_shell_test | wc -l ` == "1" ]
}

function teardown {
    rm -rf $BATS_TMPDIR/$TIMESTAMP
    # Removing docker container for image "ansible_server"
    if [ "$STOP_DOCKER_CONTAINER_AFTER_TEST" = "true" ]; then
      sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ansible_server --format="{{.ID}}"))
    fi
}