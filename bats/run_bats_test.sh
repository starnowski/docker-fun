#!/bin/bash
set -e

#Run test
sudo bats -rt "$1"
BATS_EXIT_CODE="$?"
echo "bats exit code is $BATS_EXIT_CODE"
exit "$BATS_EXIT_CODE"
