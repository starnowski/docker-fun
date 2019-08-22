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
  export ANSIBLE_SERVER_DIR="$BATS_TEST_DIRNAME/../../images/ansible_server"
  echo "docker compose dir is $ANSIBLE_WITH_SSH_SERVER_DIR" >&3
  mkdir -p $BATS_TMPDIR/John_keys
}

function resolve_ssh_server_container_id_by_image_name {
    echo $(sudo docker ps -a -q --filter name=$1 --format="{{.ID}}")
}

function resolve_ssh_server_container_id_by_service_name {
    echo $(sudo docker-compose ps -q test_ssh_server)
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


    DOCKER_CONTAINER_ID=`resolve_ssh_server_container_id_by_image_name test_ssh_server_container`
    #DOCKER_CONTAINER_ID=$(resolve_ssh_server_container_id_by_service_name)
    echo "Docker container id is $DOCKER_CONTAINER_ID" >&3

    # copy ssh keys
    copy_non_root_user_ssh_private_key_from_container $DOCKER_CONTAINER_ID $BATS_TMPDIR/John_keys/id_rsa >&3
    docker-compose exec test_ssh_server cp /home/John/.ssh/id_rsa /ssh_keys_vol/id_rsa >&3
    docker-compose exec ansible_machine ls /ssh_keys_vol >&3

    # copy ansible settings
    DOCKER_CONTAINER_ID=`resolve_ssh_server_container_id_by_image_name ansible_machine_container`
    run  docker-compose exec ansible_machine mkdir -p /etc/ansible
    sudo docker cp $ANSIBLE_SERVER_DIR/ansible_project/ansible.cfg ansible_machine_container:/etc/ansible/ansible.cfg >&3

    # when
    # https://stackoverflow.com/questions/18195142/safely-limiting-ansible-playbooks-to-a-single-machine - Setting host group
    run  docker-compose exec ansible_machine ansible-playbook -i /project/hosts.ini -e 'command_to_run="whoami"' -e 'hosts_group=test_ssh_server_group' -e "ansible_user=John" -e "ansible_ssh_private_key_file=/ssh_keys_vol/id_rsa" /project/run_shell_on_any_hosts.yml -vvv

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    echo "$output" > $BATS_TMPDIR/output_ansible
    grep '"stdout": "John"' $BATS_TMPDIR/output_ansible >&3
    [ "$?" -eq 0 ]
}

@test "Should run docker compose and run ansible playbook and execute command in login shell mode on ssh server" {
    # given
    pushd  $ANSIBLE_WITH_SSH_SERVER_DIR
    docker-compose up --detach  >&3
    docker-compose ps >&3


    DOCKER_CONTAINER_ID=`resolve_ssh_server_container_id_by_image_name test_ssh_server_container`
    #DOCKER_CONTAINER_ID=$(resolve_ssh_server_container_id_by_service_name)
    echo "Docker container id is $DOCKER_CONTAINER_ID" >&3

    # copy ssh keys
    copy_non_root_user_ssh_private_key_from_container $DOCKER_CONTAINER_ID $BATS_TMPDIR/John_keys/id_rsa >&3
    docker-compose exec test_ssh_server cp /home/John/.ssh/id_rsa /ssh_keys_vol/id_rsa >&3
    docker-compose exec ansible_machine ls /ssh_keys_vol >&3

    # Setting environment variable for user "John"
    sudo docker exec $DOCKER_CONTAINER_ID bash -lc "echo \"export BASH_LOGINS_SHELL_TEST_VALUE=_XXXX_$TIMESTAMP\" >> /home/John/.bash_profile" >&3
    # print .bashrc file for "John" user
    sudo docker exec $DOCKER_CONTAINER_ID cat "/home/John/.bash_profile" >&3

    # copy ansible settings
    DOCKER_CONTAINER_ID=`resolve_ssh_server_container_id_by_image_name ansible_machine_container`
    run  docker-compose exec ansible_machine mkdir -p /etc/ansible
    sudo docker cp $ANSIBLE_SERVER_DIR/ansible_project/ansible.cfg ansible_machine_container:/etc/ansible/ansible.cfg >&3

    # create /result_dir
    docker-compose exec test_ssh_server mkdir /result_dir
    docker-compose exec test_ssh_server chmod 777 /result_dir



    # when
    # https://stackoverflow.com/questions/18195142/safely-limiting-ansible-playbooks-to-a-single-machine - Setting host group
    run  docker-compose exec ansible_machine ansible-playbook -i /project/hosts.ini -e '_command="echo the value is $BASH_LOGINS_SHELL_TEST_VALUE; echo $BASH_LOGINS_SHELL_TEST_VALUE | tee /result_dir/result_file.xxx; chmod 777 /result_dir/result_file.xxx; ls -la /result_dir"' -e 'hosts_group=test_ssh_server_group' -e "ansible_user=John" -e "ansible_ssh_private_key_file=/ssh_keys_vol/id_rsa" /project/run_command_with_login_shell_on_any_hosts.yml -vvv
    echo "output is --> $output <--"  >&3

    # then
    mkdir $BATS_TMPDIR/$TIMESTAMP
    sudo docker cp test_ssh_server_container:/result_dir/result_file.xxx $BATS_TMPDIR/$TIMESTAMP/result_file.xxx
    run cat $BATS_TMPDIR/$TIMESTAMP/result_file.xxx
    echo "output is --> $output <--"  >&3
    [ "${lines[0]}" = "_XXXX_$TIMESTAMP" ]
}

function teardown {
    docker-compose down --volumes
    popd
}