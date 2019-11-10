#!/bin/bash

#!/usr/bin/expect

set timeout 20

set ip [lindex $argv 0]

set user [lindex $argv 1]

set password [lindex $argv 2]

set test_text [lindex $argv 3]

set test_file_path [lindex $argv 3]

spawn ssh "$user\@$ip && echo 'Current user is $(pwd), $test_text' > '$test_file_path'"

expect "Password:"

send "$password\r";