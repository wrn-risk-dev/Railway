#!/bin/bash
set -e

mkdir -p /var/run/sshd /run/sshd
ssh-keygen -A

echo "=== sshd config test ==="
/usr/sbin/sshd -t
echo "=== listening ==="
ss -tulnp | grep 22 || true

exec /usr/sbin/sshd -D -e
