#!/bin/sh
set -e

dd if=/dev/random of=/tmp/aes.key bs=32 count=1 >& /dev/null

# aes-128-cbc
dd if=/dev/random of=/tmp/plaintext bs=32 count=1 >& /dev/null
openssl aes-128-cbc -pbkdf2 -e -kfile /tmp/aes.key -in /tmp/plaintext -out /tmp/encrypted -engine afalg >& /dev/null
openssl aes-128-cbc -pbkdf2 -d -kfile /tmp/aes.key -in /tmp/encrypted -out /tmp/plaintext2 -engine afalg >& /dev/null
diff -q /tmp/plaintext /tmp/plaintext2

# aes-256-cbc
dd if=/dev/random of=/tmp/plaintext bs=32 count=1 >& /dev/null
openssl aes-256-cbc -pbkdf2 -e -kfile /tmp/aes.key -in /tmp/plaintext -out /tmp/encrypted -engine afalg >& /dev/null
openssl aes-256-cbc -pbkdf2 -d -kfile /tmp/aes.key -in /tmp/encrypted -out /tmp/plaintext2 -engine afalg >& /dev/null
diff -q /tmp/plaintext /tmp/plaintext2

# aes-128-ecb
dd if=/dev/random of=/tmp/plaintext bs=32 count=1 >& /dev/null
openssl aes-128-ecb -pbkdf2 -e -kfile /tmp/aes.key -in /tmp/plaintext -out /tmp/encrypted -engine afalg >& /dev/null
openssl aes-128-ecb -pbkdf2 -d -kfile /tmp/aes.key -in /tmp/encrypted -out /tmp/plaintext2 -engine afalg >& /dev/null
diff -q /tmp/plaintext /tmp/plaintext2

# aes-256-ecb
dd if=/dev/random of=/tmp/plaintext bs=32 count=1 >& /dev/null
openssl aes-256-ecb -pbkdf2 -e -kfile /tmp/aes.key -in /tmp/plaintext -out /tmp/encrypted -engine afalg >& /dev/null
openssl aes-256-ecb -pbkdf2 -d -kfile /tmp/aes.key -in /tmp/encrypted -out /tmp/plaintext2 -engine afalg >& /dev/null
diff -q /tmp/plaintext /tmp/plaintext2

rm /tmp/encrypted >& /dev/null
rm /tmp/plaintext >& /dev/null
rm /tmp/plaintext2 >& /dev/null
rm /tmp/aes.key >& /dev/null

echo "PASS"
exit 0
