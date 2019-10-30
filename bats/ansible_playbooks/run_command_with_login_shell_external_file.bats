#
# Usage:
# bats -rt .
# or run:
# bats -t run_command_with_login_shell_external_file.bats
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

@test "[run_command_with_login_shell_external_file] test file should contains text 'This is test content'" {
   # given
   [ -e "$BATS_TEST_DIRNAME/uploaded_files/text_file_with_content" ]

   # when
   run cat "$BATS_TEST_DIRNAME/uploaded_files/text_file_with_content"

   # then
   echo "$output" >&3
   [ "${lines[0]}" = "This is test content" ]
}

@test "[run_command_with_login_shell_external_file] should display content of passed test file during command execution" {
    export STOP_DOCKER_CONTAINER_AFTER_TEST=true
    sudo docker run --name ansible_server_bats_test -dt -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project ansible_server
    cp "$BATS_TEST_DIRNAME/uploaded_files/text_file_with_content" "$BATS_TMPDIR/$TIMESTAMP/"

    # when
    sudo docker exec ansible_server_bats_test  ansible-playbook -e '_run_command_files=/result_dir/text_file_with_content' -e '_command="cat $RUN_COMMAND_FILES_DIR/text_file_with_content | tee /result_dir/test_output"' /project/run_command_with_login_shell_on_localhost.yml -vvv

    # then
    run cat $BATS_TMPDIR/$TIMESTAMP/test_output
    echo "output is --> $output <--"  >&3
    [ "${lines[0]}" = "This is test content" ]
}

@test "[run_command_with_login_shell_external_file] test scripts should create specified files with certain content" {
   # given
   [ -e "$BATS_TEST_DIRNAME/uploaded_files/print_hello.sh" ]
   [ -e "$BATS_TEST_DIRNAME/uploaded_files/print_world.sh" ]
   [ ! -e "$BATS_TMPDIR/$TIMESTAMP/hello" ]
   [ ! -e "$BATS_TMPDIR/$TIMESTAMP/world" ]

   # when
   run bash -lc "$BATS_TEST_DIRNAME/uploaded_files/print_hello.sh $BATS_TMPDIR/$TIMESTAMP/hello && $BATS_TEST_DIRNAME/uploaded_files/print_world.sh $BATS_TMPDIR/$TIMESTAMP/world"

   # then
   echo "$output" >&3
   [ $status -eq 0 ]
   [ -e "$BATS_TMPDIR/$TIMESTAMP/hello" ]
   [ -e "$BATS_TMPDIR/$TIMESTAMP/world" ]
   [ `cat $BATS_TMPDIR/$TIMESTAMP/hello` == "hello" ]
   [ `cat $BATS_TMPDIR/$TIMESTAMP/world` == "world" ]
}

@test "[run_command_with_login_shell_external_file] should run tests scripts passed during command execution" {
    export STOP_DOCKER_CONTAINER_AFTER_TEST=true
    sudo docker run --name ansible_server_bats_test -dt -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project ansible_server
    cp "$BATS_TEST_DIRNAME/uploaded_files/print_hello.sh" "$BATS_TMPDIR/$TIMESTAMP/"
    cp "$BATS_TEST_DIRNAME/uploaded_files/print_world.sh" "$BATS_TMPDIR/$TIMESTAMP/"

    # when
   run sudo docker exec ansible_server_bats_test  ansible-playbook -e '_run_command_files=/result_dir/print_hello.sh:/result_dir/print_world.sh' -e '_command="chmod +x $RUN_COMMAND_FILES_DIR/print_hello.sh; chmod +x $RUN_COMMAND_FILES_DIR/print_world.sh; $RUN_COMMAND_FILES_DIR/print_hello.sh /result_dir/hello_output; $RUN_COMMAND_FILES_DIR/print_world.sh /result_dir/world_output"' /project/run_command_with_login_shell_on_localhost.yml -vvv

    # then
   echo "$output" >&3
   [ "$status" -eq "0" ]
   [ -e "$BATS_TMPDIR/$TIMESTAMP/hello_output" ]
   [ -e "$BATS_TMPDIR/$TIMESTAMP/world_output" ]
   [ `cat $BATS_TMPDIR/$TIMESTAMP/hello_output` == "hello" ]
   [ `cat $BATS_TMPDIR/$TIMESTAMP/world_output` == "world" ]
}

@test "[run_command_with_login_shell_external_file] should run tests scripts passed during command execution without changing of their permissions" {
    export STOP_DOCKER_CONTAINER_AFTER_TEST=true
    sudo docker run --name ansible_server_bats_test -dt -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project ansible_server
    cp "$BATS_TEST_DIRNAME/uploaded_files/print_hello.sh" "$BATS_TMPDIR/$TIMESTAMP/"
    cp "$BATS_TEST_DIRNAME/uploaded_files/print_world.sh" "$BATS_TMPDIR/$TIMESTAMP/"

    # when
   run sudo docker exec ansible_server_bats_test  ansible-playbook -e '_run_command_scripts=/result_dir/print_hello.sh:/result_dir/print_world.sh' -e '_command="$RUN_COMMAND_SCRIPTS_DIR/print_hello.sh /result_dir/hello_output; $RUN_COMMAND_SCRIPTS_DIR/print_world.sh /result_dir/world_output"' /project/run_command_with_login_shell_on_localhost.yml -vvv

    # then
   echo "$output" >&3
   [ "$status" -eq "0" ]
   [ -e "$BATS_TMPDIR/$TIMESTAMP/hello_output" ]
   [ -e "$BATS_TMPDIR/$TIMESTAMP/world_output" ]
   [ `cat $BATS_TMPDIR/$TIMESTAMP/hello_output` == "hello" ]
   [ `cat $BATS_TMPDIR/$TIMESTAMP/world_output` == "world" ]
}

@test "[run_command_with_login_shell_external_file] should delete temporary directories for scripts and files after command execution" {
    export STOP_DOCKER_CONTAINER_AFTER_TEST=true
    sudo docker run --name ansible_server_bats_test -dt -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project ansible_server
    cp "$BATS_TEST_DIRNAME/uploaded_files/print_hello.sh" "$BATS_TMPDIR/$TIMESTAMP/"
    cp "$BATS_TEST_DIRNAME/uploaded_files/print_world.sh" "$BATS_TMPDIR/$TIMESTAMP/"
    cp "$BATS_TEST_DIRNAME/uploaded_files/text_file_with_content" "$BATS_TMPDIR/$TIMESTAMP/"

    # when
   run sudo docker exec ansible_server_bats_test  ansible-playbook -e '_run_command_scripts=/result_dir/print_hello.sh:/result_dir/print_world.sh' -e '_run_command_files=/result_dir/text_file_with_content' -e '_command="echo $RUN_COMMAND_SCRIPTS_DIR | tee /result_dir/scripts_dir_path; echo $RUN_COMMAND_FILES_DIR | tee /result_dir/files_dir_path;"' /project/run_command_with_login_shell_on_localhost.yml -vvv

    # then
   echo "output is --> $output <--" >&3
   [ "$status" -eq "0" ]

   [ -e "$BATS_TMPDIR/$TIMESTAMP/scripts_dir_path" ]
   [ -e "$BATS_TMPDIR/$TIMESTAMP/files_dir_path" ]

   SCRIPT_DIR_PATH=`cat $BATS_TMPDIR/$TIMESTAMP/scripts_dir_path`
   FILES_DIR_PATH=`cat $BATS_TMPDIR/$TIMESTAMP/files_dir_path`
   # check that scripts and files directory were deleted after command execution
   # script directory should not exist
   run sudo docker exec ansible_server_bats_test test -e $SCRIPT_DIR_PATH
   [ "$status" -ne 0 ]
   # files directory should not exist
   run sudo docker exec ansible_server_bats_test test -e $FILES_DIR_PATH
   [ "$status" -ne 0 ]
}

function teardown {
    rm -rf $BATS_TMPDIR/$TIMESTAMP
    # Removing docker container for image "ansible_server"
    if [ "$STOP_DOCKER_CONTAINER_AFTER_TEST" = "true" ]; then
      sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ansible_server --format="{{.ID}}"))
    fi
}