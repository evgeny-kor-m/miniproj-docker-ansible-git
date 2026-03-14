FROM ubuntu:24.04

WORKDIR /app


RUN apt-get update && apt-get install -y openssh-server \
    sudo \
    python3 python3-pip python3-venv\
    curl \
    net-tools \
    sshpass \
    iputils-ping \
    ufw \
    && rm -rf /var/lib/apt/lists/*

#  RUN ssh-keygen -A && \
RUN  userdel -r ubuntu || true && groupdel ubuntu || true
# 3. Создаем группу docker-host с GID 1000 (соответствует группе docker на хосте WSL/Linux)  # Check local docker GID :  getent group docker | cut -d: -f3 #
RUN  groupadd -g 1000 docker-host
# 4. Создаем пользователя ansible и настраиваем SSH
RUN  useradd -m -s /bin/bash ansible && \
     # Добавляем ansible в sudo и в нашу новую группу docker-host
     usermod -aG sudo,docker-host ansible && \
     echo PubkeyAuthentication yes >> /etc/ssh/sshd_config && \
     echo PasswordAuthentication yes >> /etc/ssh/sshd_config && \
     echo "ansible:ansible" | chpasswd &&\
     echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
     mkdir -p /home/ansible/.ssh && \
     mkdir -p /run/sshd 
    
# to remain clean environment use venv for python packages
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY ansible-slave/entrypoint.sh .
RUN chmod +x entrypoint.sh
# EntryPoint: defines a command that will be executed when the container is launched.
# CMD: defines the default arguments for EntryPoint or a command if EntryPoint is not indicated.
# In this case, EntryPoint.sh is launched, and if other arguments are not indicated, then 'Bash'.
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/usr/sbin/sshd", "-D"]

