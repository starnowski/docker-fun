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
  sudo docker build -t ubuntu_16_ssh $SSH_SERVER_DIR >&3
}


@test "Should run docker container and be able to login via ssh as root user and execute echo \"whoami\" command" {
    # given
    pushd  $SSH_SERVER_DIR
    sudo docker run -d -P --name test_sshd ubuntu_16_ssh >&3
    DOCKER_CONTAINER_ID=$(sudo docker ps -a -q --filter ancestor=ubuntu_16_ssh --format="{{.ID}}")
    echo "Docker container id is $DOCKER_CONTAINER_ID" >&3
    DOCKER_CONTAINER_HOSTNAME=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' test_sshd) >&3
    echo "Docker container hostname is $DOCKER_CONTAINER_HOSTNAME" >&3

    # when

    #https://www.cyberciti.biz/faq/unix-linux-execute-command-using-ssh/
    run sudo ssh root:root_pass@$DOCKER_CONTAINER_HOSTNAME whoami >&3

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = 'root' ]
}


function teardown {
    sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ubuntu_16_ssh --format="{{.ID}}"))
    popd
}