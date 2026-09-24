FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-server \
    openssh-sftp-server \
    sudo \
    curl \
    wget \
    git \
    nano \
    vim \
    net-tools \
    iproute2 \
    python3 \
    python3-pip \
    nodejs \
    npm \
    htop \
    tmux \
    screen \
    cron \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/sshd /run/sshd

RUN echo 'root:root' | chpasswd

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Subsystem sftp line ကို ဒီမှာ လုံးဝမထည့်ပါနှင့်

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 22
EXPOSE 8080

CMD ["/start.sh"]
