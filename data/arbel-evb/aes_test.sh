#!/bin/sh
set -e
log_file="/tmp/log/aes_test.log"

# generate a random password
openssl rand -hex 4 > /tmp/aes.pass

# aes-128-cbc
dd if=/dev/random of=/tmp/plaintext bs=32 count=1 >& /dev/null
openssl aes-128-cbc -pbkdf2 -e -kfile /tmp/aes.pass -in /tmp/plaintext -out /tmp/encrypted -engine afalg &> $log_file
openssl aes-128-cbc -pbkdf2 -d -kfile /tmp/aes.pass -in /tmp/encrypted -out /tmp/plaintext2 -engine afalg &> $log_file
diff -q /tmp/plaintext /tmp/plaintext2

# aes-256-cbc
dd if=/dev/random of=/tmp/plaintext bs=32 count=1 >& /dev/null
openssl aes-256-cbc -pbkdf2 -e -kfile /tmp/aes.pass -in /tmp/plaintext -out /tmp/encrypted -engine afalg >& $log_file
openssl aes-256-cbc -pbkdf2 -d -kfile /tmp/aes.pass -in /tmp/encrypted -out /tmp/plaintext2 -engine afalg >& $log_file
diff -q /tmp/plaintext /tmp/plaintext2

rm /tmp/encrypted >& /dev/null
rm /tmp/plaintext >& /dev/null
rm /tmp/plaintext2 >& /dev/null
rm /tmp/aes.pass >& /dev/null

echo "PASS" >> $log_file
echo "PASS"
exit 0
