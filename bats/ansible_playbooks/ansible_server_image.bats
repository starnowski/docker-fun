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

@test "[ansible_server_image] Should create script with passed command" {
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

@test "[ansible_server_image] Should create script with passed command and the script needs to be executable" {
    # when
    sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server  ansible-playbook -e '_test_do_not_change_file_access=true' -e '_command="exit 7"' -e "_script_path=/result_dir/tmp_script.sh" /project/create_shell_script_on_localhost.yml -vvv
    run stat -c "%a %n" $BATS_TMPDIR/$TIMESTAMP/tmp_script.sh

    # then
    echo "output is --> $output <--" >&3
    [ "${lines[0]}" = "700 $BATS_TMPDIR/$TIMESTAMP/tmp_script.sh" ]
}

@test "[ansible_server_image] Should create script with passed command and return exit returned by internal code" {

    # when
    sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server  ansible-playbook -e '_command="./return_passed_exit_code.sh 55"' -e "_script_path=/result_dir/tmp_script.sh" /project/create_shell_script_on_localhost.yml -vvv
    # script "./return_passed_exit_code.sh", passed to shell script, is located at $BATS_TEST_DIRNAME, that is why the directory change is required.
    pushd $BATS_TEST_DIRNAME
    run $BATS_TMPDIR/$TIMESTAMP/tmp_script.sh
    popd

    # then
    echo "output is --> $output <--" >&3
    echo "status is $status" >&3
    [ "$status" -eq 55 ]
    [ "${lines[0]}" = 'Returned code is 55' ]
}

@test "[ansible_server_image] Should create script with passed command and run command on docker container" {
    # when
    sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server  ansible-playbook -e '_command="touch /result_dir/result_file.xxx && chmod 700 /result_dir/result_file.xxx"' /project/run_command_with_login_shell_on_localhost.yml -vvv
    run stat -c "%a %n" $BATS_TMPDIR/$TIMESTAMP/result_file.xxx

    # then
    echo "output is --> $output <--"  >&3
    [ "${lines[0]}" = "700 $BATS_TMPDIR/$TIMESTAMP/result_file.xxx" ]
}

@test "[ansible_server_image] Should delete temporary created script file" {
    # given
    export STOP_DOCKER_CONTAINER_AFTER_TEST=true

    # when
    sudo docker run --name ansible_server_bats_test -dt -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project ansible_server

    sudo docker exec ansible_server_bats_test  ansible-playbook -e '_command="echo \"script name is $0\" ; echo \"$0\" | tee /result_dir/result_file.xxx ; chmod 777 /result_dir/result_file.xxx"' /project/run_command_with_login_shell_on_localhost.yml -vvv

    run stat -c "%a %n" $BATS_TMPDIR/$TIMESTAMP/result_file.xxx

    # then
    echo "output is --> $output <--" >&3
    [ "${lines[0]}" = "777 $BATS_TMPDIR/$TIMESTAMP/result_file.xxx" ]
    run cat $BATS_TMPDIR/$TIMESTAMP/result_file.xxx
    echo "file output is --> $output <--"  >&3
    [ -n "${lines[0]}" ]
    SCRIPT_FILE_PATH="${lines[0]}"

    # check that script file was deleted after command execution
    # script file should not exist
    run sudo docker exec ansible_server_bats_test test -e $SCRIPT_FILE_PATH
    [ "$status" -ne 0 ]
}

@test "[ansible_server_image] Should create script with passed command and run it in shell login mode" {
    # given
    export STOP_DOCKER_CONTAINER_AFTER_TEST=true
    sudo docker run --name ansible_server_bats_test -dt -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project ansible_server
    sudo docker exec ansible_server_bats_test bash -lc "echo \"export BASH_LOGINS_SHELL_TEST_VALUE=_XXXX_$TIMESTAMP\" >> /root/.bash_profile" >&3

    # when
    sudo docker exec ansible_server_bats_test  ansible-playbook -e '_command="echo the value is $BASH_LOGINS_SHELL_TEST_VALUE; echo $BASH_LOGINS_SHELL_TEST_VALUE | tee /result_dir/result_file.xxx; chmod 777 /result_dir/result_file.xxx; ls -la /result_dir"' /project/run_command_with_login_shell_on_localhost.yml -vvv

    echo "output is --> $output <--"  >&3

    # then
    run cat $BATS_TMPDIR/$TIMESTAMP/result_file.xxx
    echo "output is --> $output <--"  >&3
    [ "${lines[0]}" = "_XXXX_$TIMESTAMP" ]
}

function teardown {
    rm -rf $BATS_TMPDIR/$TIMESTAMP
    # Removing docker container for image "ansible_server"
    if [ "$STOP_DOCKER_CONTAINER_AFTER_TEST" = "true" ]; then
      sudo docker rm $(sudo docker stop $(sudo docker ps -a -q --filter ancestor=ansible_server --format="{{.ID}}"))
    fi
}
