#!/bin/bash


function waitUntilBarrierWillBeRemoved {
    checkCount=1
    timeoutInSeconds=180
    while : ; do
        set +e
        test ! -e "$1"
        [[ "$?" -ne 0 && $checkCount -ne $timeoutInSeconds ]] || break
        checkCount=$(( checkCount+1 ))
        echo "Waiting $checkCount seconds to release lock $1"
        sleep 1
    done
    set -e
}

ITEM=$1
LOCKS_DIR="$2"

if [[ "$ITEM" == "l1" ]] ; then
    rm -f --preserve-root $LOCKS_DIR/barrier1.lock
    sleep 2
    waitUntilBarrierWillBeRemoved "$LOCKS_DIR/barrier2.lock"
else
    rm -f --preserve-root $LOCKS_DIR/barrier2.lock
    sleep 2
    waitUntilBarrierWillBeRemoved "$LOCKS_DIR/barrier1.lock"
fi

touch "$LOCKS_DIR/${ITEM}_finished"
chmod 777 "$LOCKS_DIR/${ITEM}_finished"