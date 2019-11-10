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
  mkdir -p $BATS_TMPDIR/John_keys
}

function resolve_container_id_by_image_name {
    echo $(sudo docker ps -a -q --filter ancestor=centos_7_ssh --format="{{.ID}}")
}

function resolve_container_hostname_by_image_name {
    echo $(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' test_sshd)
}

function copy_non_root_user_ssh_private_key_from_container {
    local _ssh_user=${3:-John}
    sudo docker cp $1:/home/$_ssh_user/.ssh/id_rsa $2
    # change owner
    sudo chown $(whoami):$(whoami) $2
    chmod 600 $2
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
    mkdir -p $BATS_TMPDIR/Mike_keys
    sudo docker run -d -P --name test_sshd -e PASSLOGINUSER_SSH_USER=Don -e PASSLOGINUSER_SSH_PASSWORD=xxx569 centos_7_ssh >&3
    DOCKER_CONTAINER_ID=$(resolve_container_id_by_image_name)
    DOCKER_CONTAINER_HOSTNAME=$(resolve_container_hostname_by_image_name)

    # wait until docker container will be initialized
    wait_until_container_status_will_be_healthy test_sshd 20

    # copy ssh keys
    copy_non_root_user_ssh_private_key_from_container $DOCKER_CONTAINER_ID $BATS_TMPDIR/Mike_keys/id_rsa Mike
    sudo docker exec $DOCKER_CONTAINER_ID bash -lc "echo export TEST_VALUE=_XXXX_$TIMESTAMP >> /home/Mike/.bashrc" >&3
    # print .bashrc file for "Mike" user
    #sudo docker exec $DOCKER_CONTAINER_ID cat "/home/Mike/.bashrc" >&3
    #sudo docker exec $DOCKER_CONTAINER_ID cat "/home/Mike/.profile" >&3
    remove_ssh_key_for_docker_container_hostname $DOCKER_CONTAINER_HOSTNAME

    # when
    run ssh -o LogLevel=ERROR -i $BATS_TMPDIR/Mike_keys/id_rsa -o "StrictHostKeyChecking=no" -l Mike -t $DOCKER_CONTAINER_HOSTNAME bash -i 'printTestValue.sh && echo "Current user is "$(whoami)'

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" =~ 'Test values is '\[$TEST_VALUE.*\] ]]
    [[ "${lines[1]}" =~ 'Current user is Mike' ]]
}


function teardown {
    sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=centos_7_ssh --format="{{.ID}}"))
}