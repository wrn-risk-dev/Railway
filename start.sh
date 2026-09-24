#!/bin/bash
set -e

# Runtime directories
mkdir -p /var/run/sshd /run/sshd

# Host keys ဖန်တီး (container rebuild တိုင်း အသစ်)
ssh-keygen -A

# Config syntax စစ်
echo "=== sshd -t ==="
/usr/sbin/sshd -t

# Port 22 listen ဖြစ်နေမနေ စစ်
echo "=== listening ports ==="
ss -tulnp | grep 22 || true

# SFTP subsystem ရှိမရှိ စစ်
echo "=== SFTP subsystem ==="
grep -i "subsystem" /etc/ssh/sshd_config || echo "no subsystem line!"

# sshd run (foreground, log to stderr)
exec /usr/sbin/sshd -D -e
