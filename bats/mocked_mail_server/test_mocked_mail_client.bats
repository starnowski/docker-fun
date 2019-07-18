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
    # Checking if no email file (file with extension '.eml' )
    [ ! -f $MOCKED_MAIL_SERVER_DIR/email/*.eml ]
     docker-compose up --detach  >&3
     docker-compose ps >&3

    # when
    # https://tecadmin.net/ways-to-send-email-from-linux-command-line/ - Sending mail
    #run  docker-compose exec centos_im mail -v -s "Test Subject" -S 'smtp=smtp://fakesmtp:1025' -S 'from=mister.tee@trash.com' szymon.tar@example.com

    # bash - https://stackoverflow.com/questions/35703317/docker-exec-write-text-to-file-in-container
    run  docker-compose exec centos_im bash -c 'echo "test content" | mail -v -s "Test Subject" -S smtp=smtp://fakesmtp:25 -S from=mister.tee@trash.com szymon.tar@example.com'

    # then
    echo "output is --> $output <--"  >&3
    [ "$status" -eq 0 ]
    grep 'From: mister.tee@trash.com' $MOCKED_MAIL_SERVER_DIR/email/*
    [ "$?" -eq 0 ]
    grep 'To: szymon.tar@example.com' $MOCKED_MAIL_SERVER_DIR/email/*
    [ "$?" -eq 0 ]
    grep 'Subject: Test Subject' $MOCKED_MAIL_SERVER_DIR/email/*
    [ "$?" -eq 0 ]
    grep 'test content' $MOCKED_MAIL_SERVER_DIR/email/*
    [ "$?" -eq 0 ]
}


function teardown {
     docker-compose down --volumes
    rm -f $MOCKED_MAIL_SERVER_DIR/email/*.eml
    popd
}