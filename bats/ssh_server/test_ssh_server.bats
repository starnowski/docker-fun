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
  mkdir -p $BATS_TMPDIR/John_keys
}


@test "Should run docker container and be able to login via ssh as \"John\" user and execute echo \"whoami\" command" {
    # given
    #https://stackoverflow.com/questions/27504187/ssh-key-generation-using-dockerfile - generate ssh keys
    sudo docker run -d -P --name test_sshd ubuntu_16_ssh >&3
    DOCKER_CONTAINER_ID=$(sudo docker ps -a -q --filter ancestor=ubuntu_16_ssh --format="{{.ID}}")
    echo "Docker container id is $DOCKER_CONTAINER_ID" >&3
    DOCKER_CONTAINER_HOSTNAME=$(sudo docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' test_sshd) >&3
    echo "Docker container hostname is $DOCKER_CONTAINER_HOSTNAME" >&3

    # copy ssh keys
    sudo docker cp $DOCKER_CONTAINER_ID:/home/John/.ssh/id_rsa $BATS_TMPDIR/John_keys/id_rsa
    echo "Print root keys directory"  >&3
    ls -la $BATS_TMPDIR/John_keys >&3
    # change owner
    sudo chown $(whoami):$(whoami) $BATS_TMPDIR/John_keys/id_rsa
    chmod 600 $BATS_TMPDIR/John_keys/id_rsa
    echo "Print root keys directory after owner changed"  >&3
    ls -la $BATS_TMPDIR/John_keys >&3
    sudo docker exec $DOCKER_CONTAINER_ID cat "/etc/ssh/sshd_config" >&3

    # when

    #https://www.cyberciti.biz/faq/unix-linux-execute-command-using-ssh/
    run ssh -i $BATS_TMPDIR/John_keys/id_rsa -o "StrictHostKeyChecking=no" -o "PasswordAuthentication=no" -l John $DOCKER_CONTAINER_HOSTNAME whoami >&3

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = 'John' ]
}


function teardown {
    sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ubuntu_16_ssh --format="{{.ID}}"))
}