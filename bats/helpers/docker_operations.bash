#!/bin/bash

function copy_from_container {
    sudo docker cp $1:$2 $3
    # change owner
    sudo chown $(whoami):$(whoami) $3
    chmod 600 $3
}