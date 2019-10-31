#!/bin/bash

set -e

if [ -n "$OPTIONAL_SSH_USER" ]; then
  echo "Checking if user $OPTIONAL_SSH_USER was created"
  test -e "/home/$OPTIONAL_SSH_USER/.ssh/authorized_keys"
fi
#TODO check ssh port