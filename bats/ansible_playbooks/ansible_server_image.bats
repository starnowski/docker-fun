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
}

@test "Should create script with passed command" {
    # given
    #docker build -t ansible_server $ANSIBLE_SERVER_DIR >&3
    
    #when
    sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server  ansible-playbook -e '_command="exit 7"' -e "_script_path=/result_dir/tmp_script.sh" /project/create_shell_script_on_localhost.yml -vvv
    run cat $BATS_TMPDIR/$TIMESTAMP/tmp_script.sh

    #then
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
    # given
    #docker build -t ansible_server $ANSIBLE_SERVER_DIR >&3

    #when
    sudo docker run --name ansible_server_bats_test -v $BATS_TMPDIR/$TIMESTAMP:/result_dir -v $ANSIBLE_SERVER_DIR/ansible_project:/project --rm ansible_server  ansible-playbook -e '_test_do_not_change_file_access=true' -e '_command="exit 7"' -e "_script_path=/result_dir/tmp_script.sh" /project/create_shell_script_on_localhost.yml -vvv
    run stat -c "%a %n" $BATS_TMPDIR/$TIMESTAMP/tmp_script.sh

    #then
    echo "output is --> $output <--"  >&3
    [ "${lines[0]}" = "700 $BATS_TMPDIR/$TIMESTAMP/tmp_script.sh" ]
}

function teardown {
    rm -rf $BATS_TMPDIR/$TIMESTAMP
}
