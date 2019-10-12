#!/bin/bash
DIRNAME="$(dirname $0)"
ansible-playbook $DIRNAME/run-command-for-items.yml -e "_command_items=$1" -e "_loop_command=$2"