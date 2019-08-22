#!/bin/bash
set -e
shopt -q login_shell && echo "Login shell" || echo "Not login shell"
echo $(shopt | grep login_shell)
echo $(shopt)
