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

@test "[ansible-custom-filters] should display greetings message to 'Szymon' and message that localhost is current host" {
    # when
    run sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server  ansible-playbook -e '_username="Szymon"' /project/custom_filters_localhost_test.yml -vvv

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    echo "$output" > $BATS_TMPDIR/$TIMESTAMP/ansible_output
    [ `grep 'Hello Szymon, it is nice to meet you.' $BATS_TMPDIR/$TIMESTAMP/ansible_output | wc -l ` == "1" ]
    [ `grep 'We are at localhost now.' $BATS_TMPDIR/$TIMESTAMP/ansible_output | wc -l ` == "1" ]
}

function teardown {
    rm -rf $BATS_TMPDIR/$TIMESTAMP
    # Removing docker container for image "ansible_server"
    if [ "$STOP_DOCKER_CONTAINER_AFTER_TEST" = "true" ]; then
      sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ansible_server --format="{{.ID}}"))
    fi
}