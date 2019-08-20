#
# Usage:
# bats -rt .
#

function setup {
  export TIMESTAMP=`date +%s`

  echo "Build ansible docker image" >&3
  ANSIBLE_SERVER_DIR="$BATS_TEST_DIRNAME/../../images/ansible_server"

  # Build only image
  sudo docker build -t ansible_server $ANSIBLE_SERVER_DIR >&3
  mkdir -p $BATS_TMPDIR/$TIMESTAMP
  export STOP_DOCKER_CONTAINER_AFTER_TEST=
}

@test "Should create script with passed command" {
    
    # when
    sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server  ansible-playbook -e '_command="exit 7"' -e "_script_path=/result_dir/tmp_script.sh" /project/create_shell_script_on_localhost.yml -vvv
    run cat $BATS_TMPDIR/$TIMESTAMP/tmp_script.sh

    # then
    echo "output is --> $output <--"  >&3
    [ "${lines[0]}" = '#!/bin/bash' ]
    [ "${lines[1]}" = 'set -e' ]
    [ "${lines[2]}" = 'exit 7' ]
    # Script "create_shell_script_on_localhost.ym" changes file permissions for tests purpose
    file_access=$(stat -c "%a %n" $BATS_TMPDIR/$TIMESTAMP/tmp_script.sh)
    echo "files access is $file_access" >&3
    [ "$file_access" = "777 $BATS_TMPDIR/$TIMESTAMP/tmp_script.sh" ]
}

@test "Should create script with passed command and the script needs to be executable" {

    # when
    sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server  ansible-playbook -e '_test_do_not_change_file_access=true' -e '_command="exit 7"' -e "_script_path=/result_dir/tmp_script.sh" /project/create_shell_script_on_localhost.yml -vvv
    run stat -c "%a %n" $BATS_TMPDIR/$TIMESTAMP/tmp_script.sh

    # then
    echo "output is --> $output <--"  >&3
    [ "${lines[0]}" = "700 $BATS_TMPDIR/$TIMESTAMP/tmp_script.sh" ]
}

@test "Should create script with passed command and run command on docker container" {

    # when
    sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server  ansible-playbook -e '_command="touch /result_dir/result_file.xxx && chmod 700 /result_dir/result_file.xxx"' /project/run_command_with_login_shell_on_localhost.yml -vvv
    run stat -c "%a %n" $BATS_TMPDIR/$TIMESTAMP/result_file.xxx

    # then
    echo "output is --> $output <--"  >&3
    [ "${lines[0]}" = "700 $BATS_TMPDIR/$TIMESTAMP/result_file.xxx" ]
}

@test "Should delete temporary created script file" {
    # given
    export STOP_DOCKER_CONTAINER_AFTER_TEST=true


    # when
    sudo docker run --name ansible_server_bats_test -dt -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project ansible_server
    #sleep 5
    sudo docker exec ansible_server_bats_test  ansible-playbook -e '_command="echo \"script name is $0\" ; echo \"$0\" | tee /result_dir/result_file.xxx ; chmod 777 /result_dir/result_file.xxx"' /project/run_command_with_login_shell_on_localhost.yml -vvv

    run stat -c "%a %n" $BATS_TMPDIR/$TIMESTAMP/result_file.xxx

    # then
    echo "output is --> $output <--"  >&3
    [ "${lines[0]}" = "777 $BATS_TMPDIR/$TIMESTAMP/result_file.xxx" ]
    run cat $BATS_TMPDIR/$TIMESTAMP/result_file.xxx
    # check that script file was deleted after command execution
    echo "file output is --> $output <--"  >&3
    [ -n "${lines[0]}" ]
    SCRIPT_FILE_PATH="${lines[0]}"
    sudo docker cp ansible_server_bats_test:$SCRIPT_FILE_PATH $BATS_TMPDIR/$TIMESTAMP/script_file.sh
    ! [ -e "$BATS_TMPDIR/$TIMESTAMP/script_file.sh" ]
}

function teardown {
    rm -rf $BATS_TMPDIR/$TIMESTAMP
    # Removing docker container for image "ansible_server"
    if [ "$STOP_DOCKER_CONTAINER_AFTER_TEST" = "true" ]; then
      sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ansible_server --format="{{.ID}}"))
    fi
}
