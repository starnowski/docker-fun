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

function waitUntilFinalFileWillBeCreated {
    checkCount=1
    timeoutInSeconds=180
    while : ; do
        set +e
        test -e "$1"
        [[ "$?" -ne 0 && $checkCount -ne $timeoutInSeconds ]] || break
        checkCount=$(( checkCount+1 ))
        echo "Waiting $checkCount seconds to final result file: $1"
        sleep 1
    done
    set -e
}

@test "test script should wait until test method will not release lock barrier" {
    # given
    touch $BATS_TMPDIR/$TIMESTAMP/barrier1.lock
    touch $BATS_TMPDIR/$TIMESTAMP/barrier2.lock
    chmod 777 $BATS_TMPDIR/$TIMESTAMP/barrier1.lock
    chmod 777 $BATS_TMPDIR/$TIMESTAMP/barrier2.lock
    $BATS_TEST_DIRNAME/../../images/ansible_server/ansible_project/test/run_task_with_two_locks.sh l1 $BATS_TMPDIR/$TIMESTAMP &
    CHILD_PROC_PID=$!
    sleep 5
    ps -p $CHILD_PROC_PID
    rm -f $BATS_TMPDIR/$TIMESTAMP/barrier2.lock

    # when
    run waitUntilFinalFileWillBeCreated $BATS_TMPDIR/$TIMESTAMP/l1_finished

    # then
    echo "$output" >&3
    [ "$status" -eq "0" ]
    [ ! -e $BATS_TMPDIR/$TIMESTAMP/barrier1.lock ]
    [ ! -e $BATS_TMPDIR/$TIMESTAMP/barrier2.lock ]
    [ -e $BATS_TMPDIR/$TIMESTAMP/l1_finished ]
}

@test "should run each command in parallel" {
    # given
    touch $BATS_TMPDIR/$TIMESTAMP/barrier1.lock
    touch $BATS_TMPDIR/$TIMESTAMP/barrier2.lock
    chmod 777 $BATS_TMPDIR/$TIMESTAMP/barrier1.lock
    chmod 777 $BATS_TMPDIR/$TIMESTAMP/barrier2.lock

    # when
    run sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server /project/run-command-for-items.sh --parallel 'l3:l4:l1:l2' '/project/test/run_task_with_two_locks.sh  "$CURRENT_ITEM" /result_dir'

    # then
    echo "$output" >&3
    [ "$status" -eq "0" ]
    [ ! -e $BATS_TMPDIR/$TIMESTAMP/barrier1.lock ]
    [ ! -e $BATS_TMPDIR/$TIMESTAMP/barrier2.lock ]
    [ -e $BATS_TMPDIR/$TIMESTAMP/l1_finished ]
    [ -e $BATS_TMPDIR/$TIMESTAMP/l2_finished ]
    [ -e $BATS_TMPDIR/$TIMESTAMP/l3_finished ]
    [ -e $BATS_TMPDIR/$TIMESTAMP/l4_finished ]
}


function teardown {
    rm -rf $BATS_TMPDIR/$TIMESTAMP
    # Removing docker container for image "ansible_server"
    if [ "$STOP_DOCKER_CONTAINER_AFTER_TEST" = "true" ]; then
      sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ansible_server --format="{{.ID}}"))
    fi
}