#!/bin/bash

function waitUntilFinalFileWillBeCreated {
    checkCount=1
    timeoutInSeconds=${2:-180}
    while : ; do
        set +e
        test -e "$1"
        [[ "$?" -ne 0 && $checkCount -ne $timeoutInSeconds ]] || break
        checkCount=$(( checkCount+1 ))
        echo "Waiting $checkCount seconds to final result file: $1"
        sleep 1
    done
    set -e
    if [[ "$checkCount" == "$timeoutInSeconds" ]] ; then
        >&2 echo "Timeout was exceeded while waiting for file \"$1\""
        exit 1
    fi
}