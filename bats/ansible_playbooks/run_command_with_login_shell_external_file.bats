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

# TODO Test file with content "This is test content"
@test "[run_command_with_login_shell_external_file] test file should contains text 'This is test content'" {
   # given
   [ -e "$BATS_TEST_DIRNAME/uploaded_files/text_file_with_content" ]

   # when
   run cat "$BATS_TEST_DIRNAME/uploaded_files/text_file_with_content"

   # then
   echo "$output" >&3
   [ "${lines[0]}" = "This is test content" ]
}

# TODO Display uploaded file
# TODO Run uploaded script

# TODO Uploaded files are deleted

function teardown {
    rm -rf $BATS_TMPDIR/$TIMESTAMP
    # Removing docker container for image "ansible_server"
    if [ "$STOP_DOCKER_CONTAINER_AFTER_TEST" = "true" ]; then
      sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ansible_server --format="{{.ID}}"))
    fi
}