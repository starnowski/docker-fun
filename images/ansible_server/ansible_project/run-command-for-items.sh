#!/bin/bash
DIRNAME="$(dirname $0)"

# Call getopt to validate the provided input.
options=$(getopt -o "" --long parallel -- "$@")
[ $? -eq 0 ] || {
    echo "Incorrect options provided"
    exit 1
}
eval set -- "$options"
while true; do
    case "$1" in
    --parallel)
        EXECUTE_PARALLEL=true
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
    ansible-playbook $DIRNAME/run-command-for-items.yml -e "_command_items='$1'" -e "_loop_command='$2'" -e "_execute_command_parallel=true" -vvvv
else
    ansible-playbook $DIRNAME/run-command-for-items.yml -e "_command_items='$1'" -e "_loop_command='$2'" -vvvv
    #ansible-playbook $DIRNAME/run-command-for-items.yml -e "_command_items='$1'" -e "_loop_command='$2'"
fi