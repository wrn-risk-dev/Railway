FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-server \
    sudo curl wget git nano vim \
    net-tools iproute2 \
    python3 python3-pip \
    nodejs npm \
    htop tmux screen cron \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd /run/sshd

# Root password (dev container အတွက်သာ)
RUN echo 'root:root' | chpasswd

# SSH config ပြင်ဆင်ခြင်း (idempotent — ဘယ်လောက်ခါ run ရင်လည်း OK)
RUN sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?Subsystem\s\+sftp.*/Subsystem sftp internal-sftp/' /etc/ssh/sshd_config

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 22
CMD ["/start.sh"]
