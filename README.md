[![Build Status](https://travis-ci.org/starnowski/docker-fun.svg?branch=master)](https://travis-ci.org/starnowski/docker-fun)

# docker-fun


* [Bash script which use ansible to parallel execution of specified command on localhost for specified array of items](#bash-script-with-ansible-parallel-command-exeuction)
* [Useful links](#useful-links)


[bash-script-with-ansible-parallel-command-exeuction]: #bash-script-with-ansible-parallel-command-exeuction
# Bash script which use ansible to parallel execution of specified command on localhost for specified array of items

TODO

* Main bash script ['run-command-for-items.sh'](https://github.com/starnowski/docker-fun/blob/master/images/ansible_server/ansible_project/run-command-for-items.sh)
* Main Ansible playbook  ['run-command-for-items.yml'](https://github.com/starnowski/docker-fun/blob/master/images/ansible_server/ansible_project/run-command-for-items.yml)
* The Ansible tasks file which contains usage of 'async', 'poll' option as also module 'async_status' ['run-command-for-items.yml'](https://github.com/starnowski/docker-fun/blob/master/images/ansible_server/ansible_project/tasks/run_command_for_items/items_parallel_executor.yml)

[useful-links]: #useful-links
# Useful links

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

#Redirection and streams operation in Bash
https://wiki.bash-hackers.org/howto/redirection_tutorial
