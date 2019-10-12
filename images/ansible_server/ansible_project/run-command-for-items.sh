#!/bin/bash

ansible-playbook run-command-for-items.yml -e "_command_items=$1" -e "_command=$2"