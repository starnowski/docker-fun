#!/bin/bash

if [ -n "$OPTIONAL_SSH_USER" ]; then
  echo "Creating user $OPTIONAL_SSH_USE"
  useradd -m -p Kent "$OPTIONAL_SSH_USER"
  mkdir -p "/home/$OPTIONAL_SSH_USER/.ssh"
  ssh-keygen -q -t rsa -N '' -f "/home/$OPTIONAL_SSH_USER/.ssh/id_rsa"
  cat "/home/$OPTIONAL_SSH_USER/.ssh/id_rsa.pub" >> "/home/$OPTIONAL_SSH_USER/.ssh/authorized_keys"
fi

/usr/sbin/sshd -D