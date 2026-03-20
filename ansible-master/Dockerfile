FROM ubuntu:24.04

WORKDIR /app

#COPY requirements.txt .

RUN apt-get update && apt-get install -y openssh-server \
    sudo \
    python3 python3-pip python3-venv\
    git \
    curl \
    vim \
    sshpass \
    net-tools \
    iputils-ping \
    ansible \
    ufw \
    && rm -rf /var/lib/apt/lists/*

# to remain clean environment use venv for python packages
RUN python3 -m venv /opt/venv  
ENV PATH="/opt/venv/bin:$PATH"

# RUN ssh-keygen -A && \
RUN useradd -m -s /bin/bash ansible && \
    usermod -aG sudo ansible && \
    echo "ansible:ansible" | chpasswd &&\
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /run/sshd \
    mkdir -p /home/ansible/.ssh

# COPY ./ansible ./ansible
COPY ansible-master/entrypoint.sh .

RUN chmod +x entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["/usr/sbin/sshd", "-D"]
