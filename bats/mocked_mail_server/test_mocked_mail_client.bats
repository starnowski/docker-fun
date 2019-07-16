#
# Usage:
# bats -rt .
#
# Tips about docker compose:
# https://runnable.com/docker/advanced-docker-compose-configuration
# http://nilhcem.com/FakeSMTP/
#

function setup {
  # https://phauer.com/2017/test-mail-server-php-docker-container/
  export TIMESTAMP=`date +%s`

  export MOCKED_MAIL_SERVER_DIR="$BATS_TEST_DIRNAME/../../images/mocked_mail_server"
  echo "docker compose dir is $MOCKED_MAIL_SERVER_DIR" >&3
}


@test "Should run docker compose and send mail from container \"centos_im\" to mail server in \"mailhog\" container" {
    # given
    pushd  $MOCKED_MAIL_SERVER_DIR
    sudo docker-compose up --detach  >&3
    sudo docker-compose ps >&3

    # when
    # https://tecadmin.net/ways-to-send-email-from-linux-command-line/ - Sending mail
    run sudo docker-compose exec centos_im mail -v -s "Test Subject" -S 'smtp=smtp://fakesmtp:1025' -S 'from=mister.tee@trash.com' szymon.tar@example.com

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
}


function teardown {
    sudo docker-compose down --volumes
    popd
}