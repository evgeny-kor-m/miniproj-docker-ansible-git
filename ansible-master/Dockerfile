FROM ubuntu:24.04

WORKDIR /app

COPY requirements.txt .

RUN apt-get update && apt-get install -y \
    python3 python3-pip python3-venv\
    openssh-server \
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

RUN pip install --no-cache-dir -r requirements.txt

COPY ./ansible ./ansible

CMD ["/usr/sbin/sshd", "-D"]