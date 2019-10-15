#!/bin/bash

# write pid to file
echo "$$" > $1

while : ; do
    sleep 10
done