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
   [ ! -e "$BATS_TMPDIR/$TIMESTAMP/hello" ]
   [ ! -e "$BATS_TMPDIR/$TIMESTAMP/world" ]
   [ `cat $BATS_TMPDIR/$TIMESTAMP/hello` == "hello" ]
   [ `cat $BATS_TMPDIR/$TIMESTAMP/world` == "world" ]
}

# TODO Run uploaded script

# TODO Uploaded files are deleted

function teardown {
    rm -rf $BATS_TMPDIR/$TIMESTAMP
    # Removing docker container for image "ansible_server"
    if [ "$STOP_DOCKER_CONTAINER_AFTER_TEST" = "true" ]; then
      sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ansible_server --format="{{.ID}}"))
    fi
}