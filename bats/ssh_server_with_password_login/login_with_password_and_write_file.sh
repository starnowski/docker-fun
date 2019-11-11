#!/usr/bin/expect

set timeout 20

set ip [lindex $argv 0]

set user [lindex $argv 1]

set password [lindex $argv 2]

set test_text [lindex $argv 3]

set test_file_path [lindex $argv 4]

#spawn ssh -o LogLevel=ERROR -o "StrictHostKeyChecking=no"  "$user\@$ip"
spawn ssh -o LogLevel=ERROR -o "StrictHostKeyChecking=no"  "$user\@$ip" "echo \"Current user is \$(whoami), $test_text\" | tee /test_dir/output_file"

expect "Password:"

send "$password\r";

#send "echo \"Current user is \$(whoami), $test_text\" | tee /test_dir/output_file \r"

expect eof