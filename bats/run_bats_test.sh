#!/bin/bash
set -e

#Run test
bats -rt "$1"

