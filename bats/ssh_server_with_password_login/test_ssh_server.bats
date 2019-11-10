#
# Usage:
# bats -rt .
#
# Tips about docker compose:
# https://runnable.com/docker/advanced-docker-compose-configuration
#

function setup {
  # https://phauer.com/2017/test-mail-server-php-docker-container/
  export TIMESTAMP=`date +%s`

  export SSH_SERVER_DIR="$BATS_TEST_DIRNAME/../../images/ssh_server"
  echo "dockerfile dir is $SSH_SERVER_DIR" >&3
  sudo docker build -t centos_7_ssh $SSH_SERVER_DIR >&3
  #sudo docker build --no-cache -t centos_7_ssh $SSH_SERVER_DIR >&3
  load $BATS_TEST_DIRNAME/../helpers/docker_operations.bash
}

function resolve_container_id_by_image_name {
    echo $(sudo docker ps -a -q --filter ancestor=centos_7_ssh --format="{{.ID}}")
}

function resolve_container_hostname_by_image_name {
    echo $(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' test_sshd)
}

#
# Function used to remove belowed error with changed the docker hostname during login via ssh command.
# https://www.cyberciti.biz/faq/warning-remote-host-identification-has-changed-error-and-solution/
#
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#@ WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED! @
#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
#IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
#
#
function remove_ssh_key_for_docker_container_hostname {
    ssh-keygen -R $1
}

function wait_until_container_status_will_be_healthy {
    checkCount=1
    timeoutInSeconds=${2:-180}
    set +e
    local _inspect_output=''
    while : ; do
        _inspect_output=`docker inspect --format='{{json .State.Health}}' $1`
        echo "Docker container status: $_inspect_output" >&3
        echo "$_inspect_output" | grep '"Status":"healthy"'
        [[ "$?" -ne 0 && $checkCount -ne $timeoutInSeconds ]] || break
        checkCount=$(( checkCount+1 ))
        echo "Waiting $checkCount seconds to final result file: $1" >&3
        sleep 1
    done
    set -e
    if [[ "$checkCount" == "$timeoutInSeconds" ]] ; then
        >&2 echo "Timeout was exceeded while waiting for container \"$1\""
        exit 1
    fi
}

@test "Should create user 'Don' during container start up, the user which can login by ssh protocol with password 'xxx569'" {
    # given
    mkdir -p $BATS_TMPDIR/test
    sudo docker run -d -P --name test_sshd -e PASSLOGINUSER_SSH_USER=Don -e PASSLOGINUSER_SSH_PASSWORD=xxx569 centos_7_ssh >&3
    DOCKER_CONTAINER_ID=$(resolve_container_id_by_image_name)
    DOCKER_CONTAINER_HOSTNAME=$(resolve_container_hostname_by_image_name)

    # wait until docker container will be initialized
    wait_until_container_status_will_be_healthy test_sshd 20

    # copy ssh keys
    sudo docker exec $DOCKER_CONTAINER_ID bash -lc "mkdir -p /test_dir && chmod 777 /test_dir" >&3

    # when
    run $BATS_TEST_DIRNAME/login_with_password_and_write_file.sh $DOCKER_CONTAINER_HOSTNAME Don xxx569 "This is a test!" /test_dir/output_file  >&3

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    copy_from_container $DOCKER_CONTAINER_ID /test_dir/output_file $BATS_TMPDIR/test/output_file
    run cat $BATS_TMPDIR/test/output_file
    [[ "${lines[0]}" =~ 'Current user is Don, This is a test!' ]]
}


function teardown {
    sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=centos_7_ssh --format="{{.ID}}"))
}