#!/bin/bash
DIRNAME="$(dirname $0)"
echo "Passed items: $1"
echo "Running command: $2"
ansible-playbook $DIRNAME/run-command-for-items.yml -e "_command_items=\"$1\"" -e "_loop_command=$2"