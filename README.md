[![Build Status](https://travis-ci.org/starnowski/docker-fun.svg?branch=master)](https://travis-ci.org/starnowski/docker-fun)

# docker-fun


* [Bash script which use ansible to parallel execution of specified command on localhost for specified array of items](#bash-script-which-use-ansible-to-parallel-execution-of-specified-command-on-localhost-for-specified-array-of-items)
* [Useful links](#useful-links)


[bash-script-which-use-ansible-to-parallel-execution-of-specified-command-on-localhost-for-specified-array-of-items]: #bash-script-which-use-ansible-to-parallel-execution-of-specified-command-on-localhost-for-specified-array-of-items
# Bash script which use ansible to parallel execution of specified command on localhost for specified array of items

* Main bash script ['run-command-for-items.sh'](https://github.com/starnowski/docker-fun/blob/master/images/ansible_server/ansible_project/run-command-for-items.sh)
* Main Ansible playbook  ['run-command-for-items.yml'](https://github.com/starnowski/docker-fun/blob/master/images/ansible_server/ansible_project/run-command-for-items.yml)
* The Ansible tasks file which contains usage of 'async', 'poll' option as also module 'async_status' ['run-command-for-items.yml'](https://github.com/starnowski/docker-fun/blob/master/images/ansible_server/ansible_project/tasks/run_command_for_items/items_parallel_executor.yml)
* The Ansible tasks file which sets facts with information like for which items the command execution succeeded, failed or did not finished ['compute_parallel_results.yml'](https://github.com/starnowski/docker-fun/blob/master/images/ansible_server/ansible_project/tasks/run_command_for_items/compute_parallel_results.yml)

### Tests
* Basic tests ['run-command-for-items-parallel.bats'](https://github.com/starnowski/docker-fun/blob/master/bats/ansible_playbooks/run-command-for-items-parallel.bats)
* Tests which shows that commands are executed in parallel ['run-command-for-items-parallel.bats'](https://github.com/starnowski/docker-fun/blob/master/bats/ansible_playbooks/run-command-for-items-concurrent.bats)
* Tests which shows that the main bash script can handle command timeout execution ['run-command-for-items-timeout.bats'](https://github.com/starnowski/docker-fun/blob/master/bats/ansible_playbooks/run-command-for-items-timeout.bats) 

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
