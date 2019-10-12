#!/bin/bash

echo $1
if [[ "$1" == "$2" ]]; then
    exit 1
fi
