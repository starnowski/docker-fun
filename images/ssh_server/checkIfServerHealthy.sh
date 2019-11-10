#!/bin/bash

set -e

if [ -n "$OPTIONAL_SSH_USER" ]; then
  echo "Checking if user $OPTIONAL_SSH_USER was created"
  test -e "/home/$OPTIONAL_SSH_USER/.ssh/authorized_keys"
fi

if [ -n "$PASSLOGINUSER_SSH_USER" ] && [ -n "$PASSLOGINUSER_SSH_PASSWORD" ]; then
  echo "Checking if user $PASSLOGINUSER_SSH_USER was created"
  test -e "/home/$PASSLOGINUSER_SSH_USER/"
fi
#TODO check ssh port