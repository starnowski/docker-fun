#!/bin/bash

set -Eeo pipefail

# Call getopt to validate the provided input.
options=$(getopt -o "" --long optional_ssh_user: -- "$@")
[ $? -eq 0 ] || {
    echo "Incorrect options provided"
    exit 1
}
eval set -- "$options"
while true; do
    case "$1" in
    --optional_ssh_user)
        shift; # The arg is next in position args
        OPTIONAL_SSH_USER=$1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done



if [ -n "$OPTIONAL_SSH_USER" ]; then
  echo "Creating user $OPTIONAL_SSH_USER"
  useradd -m -p Kent "$OPTIONAL_SSH_USER"
  mkdir -p "/home/$OPTIONAL_SSH_USER/.ssh"
  ssh-keygen -q -t rsa -N '' -f "/home/$OPTIONAL_SSH_USER/.ssh/id_rsa"
  cat "/home/$OPTIONAL_SSH_USER/.ssh/id_rsa.pub" >> "/home/$OPTIONAL_SSH_USER/.ssh/authorized_keys"
fi

if [ -n "$PASSLOGINUSER_SSH_USER" ] && [ -n "$PASSLOGINUSER_SSH_PASSWORD" ] ; then
  echo "Creating user $PASSLOGINUSER_SSH_USER with password $PASSLOGINUSER_SSH_PASSWORD"
  export pass=$(perl -e "print crypt($PASSLOGINUSER_SSH_PASSWORD, 'salt')") && export USER_ENCRYPTED_PASS=$pass
  useradd -m -p $USER_ENCRYPTED_PASS $PASSLOGINUSER_SSH_USER
fi

/usr/sbin/sshd -D