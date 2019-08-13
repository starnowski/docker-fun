#
# Usage:
# bats -rt .
#
# Tips about docker compose:
# https://runnable.com/docker/advanced-docker-compose-configuration
# http://nilhcem.com/FakeSMTP/
#

function setup {
  export TIMESTAMP=`date +%s`

  export ANSIBLE_WITH_SSH_SERVER_DIR="$BATS_TEST_DIRNAME/../../images/ansible_with_ssh_server"
  echo "docker compose dir is $ANSIBLE_WITH_SSH_SERVER_DIR" >&3
}

function resolve_ssh_server_container_id_by_image_name {
    echo $(sudo docker ps -a -q --filter ancestor=test_ssh_server --format="{{.ID}}")
}

function copy_non_root_user_ssh_private_key_from_container {
    sudo docker cp $1:/home/John/.ssh/id_rsa $2
    # change owner
    sudo chown $(whoami):$(whoami) $2
    chmod 600 $2
}


@test "Should run docker compose run ansible playbook which will be executed on container with ssh server" {
    # given
    pushd  $ANSIBLE_WITH_SSH_SERVER_DIR
    docker-compose up --detach  >&3
    docker-compose ps >&3


    DOCKER_CONTAINER_ID=$(resolve_ssh_server_container_id_by_image_name)
    echo "Docker container id is $DOCKER_CONTAINER_ID" >&3

    # copy ssh keys
    copy_non_root_user_ssh_private_key_from_container $DOCKER_CONTAINER_ID $BATS_TMPDIR/John_keys/id_rsa

    # when

    run  docker-compose exec ansible_machine ansible-playbook -e 'command_to_run="echo test1 > /home/John/test1_output"' -e "hosts_group=ssh_server" /project/run_shell_on_any_hosts.yml -vvv

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
}


function teardown {
    docker-compose down --volumes
    popd
}