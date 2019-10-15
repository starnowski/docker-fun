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
  export BACKGROUND_PROC_PID=
  load $BATS_TEST_DIRNAME/../helpers/timeout_helpers.bash
}

@test "[run-command-for-items-parallel] test script started in background should write its pid to test file and run constantly" {
    # given
    [ ! -e "$BATS_TMPDIR/$TIMESTAMP/pid_file" ]

    # when
    $BATS_TEST_DIRNAME/../../images/ansible_server/ansible_project/test/run_hang_process.sh "$BATS_TMPDIR/$TIMESTAMP/pid_file" &

    # then
    BACKGROUND_PROC_PID=$!
    waitUntilFinalFileWillBeCreated "$BATS_TMPDIR/$TIMESTAMP/pid_file"
    [ -e "$BATS_TMPDIR/$TIMESTAMP/pid_file" ]
    cat $BATS_TMPDIR/$TIMESTAMP/pid_file >&3
    [ `cat $BATS_TMPDIR/$TIMESTAMP/pid_file` == "$BACKGROUND_PROC_PID" ]
    ps -p $BACKGROUND_PROC_PID
    CURRENT_PROCESS_PID="$$"
    [ "$CURRENT_PROCESS_PID" != "$BACKGROUND_PROC_PID" ]
}

function teardown {
    # Close background process
    if [ "$BACKGROUND_PROC_PID" != "" ]; then
        kill -9 "$BACKGROUND_PROC_PID"
    fi
    rm -rf $BATS_TMPDIR/$TIMESTAMP
    # Removing docker container for image "ansible_server"
    if [ "$STOP_DOCKER_CONTAINER_AFTER_TEST" = "true" ]; then
      sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ansible_server --format="{{.ID}}"))
    fi
}