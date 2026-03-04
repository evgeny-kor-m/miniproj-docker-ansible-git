FROM ubuntu:24.04

WORKDIR /app

#COPY requirements.txt .

RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv\
    openssh-client \
    curl \
    vim \
    sshpass \
    net-tools \
    iputils-ping \
    ansible \
    && rm -rf /var/lib/apt/lists/*

# to remain clean environment use venv for python packages
RUN python3 -m venv /opt/venv  
ENV PATH="/opt/venv/bin:$PATH"

RUN ssh-keygen -A && \
    useradd -m -s /bin/bash ansible && \ 
    echo "ansible:ansible" | chpasswd &&\
    echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/ansible/.ssh && \
    chown -R ansible:ansible /home/ansible/.ssh && \
    chmod 700 /home/ansible/.ssh 

COPY ./ansible ./ansible
COPY ansible-slave/entrypoint.sh .

RUN chmod +x entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]

CMD ["tail", "-f", "/dev/null"]