#!/bin/bash

if [[ "$1" == "$2" ]]; then
    echo "Script failed: $1"
    exit 1
fi
echo "Script succeeded: $1"
