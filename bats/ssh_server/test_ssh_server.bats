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

@test "Should run docker container and be able to login via ssh as \"John\" user and execute echo \"whoami\" command" {
    # given
    sudo docker run -d -P --name test_sshd centos_7_ssh >&3
    DOCKER_CONTAINER_ID=$(resolve_container_id_by_image_name)
    echo "Docker container id is $DOCKER_CONTAINER_ID" >&3
    DOCKER_CONTAINER_HOSTNAME=$(resolve_container_hostname_by_image_name)
    echo "Docker container hostname is $DOCKER_CONTAINER_HOSTNAME" >&3

    # copy ssh keys
    copy_non_root_user_ssh_private_key_from_container $DOCKER_CONTAINER_ID $BATS_TMPDIR/John_keys/id_rsa
    echo "Print root keys directory after owner changed"  >&3
    ls -la $BATS_TMPDIR/John_keys >&3
    # print ssh server configuration
    sudo docker exec $DOCKER_CONTAINER_ID cat "/etc/ssh/sshd_config" >&3
    remove_ssh_key_for_docker_container_hostname $DOCKER_CONTAINER_HOSTNAME

    # when

    #https://www.cyberciti.biz/faq/unix-linux-execute-command-using-ssh/
    run ssh -o LogLevel=ERROR -i $BATS_TMPDIR/John_keys/id_rsa -o "StrictHostKeyChecking=no" -l John $DOCKER_CONTAINER_HOSTNAME whoami >&3

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = 'John' ]
}

@test "Should print environment variable which was set for user when login via ssh and execute echo to print variable value" {
    # given
    sudo docker run -d -P --name test_sshd centos_7_ssh >&3
    DOCKER_CONTAINER_ID=$(resolve_container_id_by_image_name)
    DOCKER_CONTAINER_HOSTNAME=$(resolve_container_hostname_by_image_name)

    # copy ssh keys
    copy_non_root_user_ssh_private_key_from_container $DOCKER_CONTAINER_ID $BATS_TMPDIR/John_keys/id_rsa
    sudo docker exec $DOCKER_CONTAINER_ID bash -lc "echo export TEST_VALUE=_XXXX_$TIMESTAMP >> /home/John/.bashrc" >&3
    # print .bashrc file for "John" user
    #sudo docker exec $DOCKER_CONTAINER_ID cat "/home/John/.bashrc" >&3
    #sudo docker exec $DOCKER_CONTAINER_ID cat "/home/John/.profile" >&3
    remove_ssh_key_for_docker_container_hostname $DOCKER_CONTAINER_HOSTNAME

    # when
    run ssh -o LogLevel=ERROR -i $BATS_TMPDIR/John_keys/id_rsa -o "StrictHostKeyChecking=no" -l John -t $DOCKER_CONTAINER_HOSTNAME bash -i 'printTestValue.sh'

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" =~ 'Test values is '\[$TEST_VALUE.*\] ]]
}

@test "Should create user 'Mike' during container start up, the user which can login by ssh protocol" {
    # given
    sudo docker run -d -P --name test_sshd -e OPTIONAL_SSH_USER=Mike centos_7_ssh >&3
    DOCKER_CONTAINER_ID=$(resolve_container_id_by_image_name)
    DOCKER_CONTAINER_HOSTNAME=$(resolve_container_hostname_by_image_name)

    # copy ssh keys
    copy_non_root_user_ssh_private_key_from_container $DOCKER_CONTAINER_ID $BATS_TMPDIR/Mike_keys/id_rsa Mike
    sudo docker exec $DOCKER_CONTAINER_ID bash -lc "echo export TEST_VALUE=_XXXX_$TIMESTAMP >> /home/Mike/.bashrc" >&3
    # print .bashrc file for "Mike" user
    #sudo docker exec $DOCKER_CONTAINER_ID cat "/home/Mike/.bashrc" >&3
    #sudo docker exec $DOCKER_CONTAINER_ID cat "/home/Mike/.profile" >&3
    remove_ssh_key_for_docker_container_hostname $DOCKER_CONTAINER_HOSTNAME

    # when
    run ssh -o LogLevel=ERROR -i $BATS_TMPDIR/Mike_keys/id_rsa -o "StrictHostKeyChecking=no" -l Mike -t $DOCKER_CONTAINER_HOSTNAME bash -i 'printTestValue.sh'

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" =~ 'Test values is '\[$TEST_VALUE.*\] ]]
}


function teardown {
    sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=centos_7_ssh --format="{{.ID}}"))
}