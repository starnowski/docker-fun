[![Build Status](https://travis-ci.org/starnowski/docker-fun.svg?branch=master)](https://travis-ci.org/starnowski/docker-fun)

# docker-fun

https://github.com/ansible/ansible-examples


https://www.mulesoft.com/tcat/tomcat-clustering


#ansible, spaces in command line variables - issue
https://stackoverflow.com/questions/32584112/ansible-spaces-in-command-line-variables


#Restapi mock server
http://www.mock-server.com/#what-is-mockserver

How to check if a shell is login/interactive/batch
https://unix.stackexchange.com/questions/26676/how-to-check-if-a-shell-is-login-interactive-batch
https://www.linuxquestions.org/questions/programming-9/how-to-check-in-a-script-whether-the-shell-is-login-or-non-login-360629/

To check if you are in an interactive shell:

[[ $- == *i* ]] && echo 'Interactive' || echo 'Not interactive'

To check if you are in a login shell:

shopt -q login_shell && echo 'Login shell' || echo 'Not login shell'