#!/bin/bash
DIRNAME="$(dirname $0)"

# Call getopt to validate the provided input.
options=$(getopt -o "" --long parallel,asyncStatusRetries:,asyncStatusDelay:,asyncTimeout: -- "$@")
[ $? -eq 0 ] || {
    echo "Incorrect options provided"
    exit 1
}

ASYNC_STATUS_RETRIES=30
ASYNC_STATUS_DELAY=10
ASYNC_TIMEOUT=1000
eval set -- "$options"
while true; do
    case "$1" in
    --parallel)
        EXECUTE_PARALLEL=true
        ;;
    --asyncStatusRetries)
        shift;
        ASYNC_STATUS_RETRIES=$1
        ;;
    --asyncStatusDelay)
        shift;
        ASYNC_STATUS_DELAY=$1
        ;;
    --asyncTimeout)
        shift;
        ASYNC_TIMEOUT=$1
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done

echo "Passed items: $1"
echo "Running command: $2"
if [[ "$EXECUTE_PARALLEL" == "true" ]] ; then
    ansible-playbook $DIRNAME/run-command-for-items.yml -e "_command_items='$1'" -e "_loop_command='$2'" -e "_execute_command_parallel=true" -e "_execute_command_parallel_async_status_retries=$ASYNC_STATUS_RETRIES" -e "_execute_command_parallel_async_status_delay=$ASYNC_STATUS_DELAY" -e "_execute_command_parallel_async_timeout=$ASYNC_TIMEOUT"  -vvvv
else
    ansible-playbook $DIRNAME/run-command-for-items.yml -e "_command_items='$1'" -e "_loop_command='$2'" -vvvv
    #ansible-playbook $DIRNAME/run-command-for-items.yml -e "_command_items='$1'" -e "_loop_command='$2'"
fi