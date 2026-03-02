# mini-project

## Created a Private Repository житч README file - mini-project
git clone https://github.com/evgeny-kor-m/mini-project.git
git branch worker
git checkout worker
git branch

nano ~/.docker/config.json -> "credHelpers": "wincred.exe" - Connects Docker running in console to Windows Credential Manager.

Created Makefile
```
make clean - remove all (images, containers, volumes, net)
make prerequisite - create net, volume
```

## Create ssh_key folder and generate key
mkdir .ssh_key
ssh-keygen -t rsa -b 4096 -f ./.ssh_key/id_rsa -N ""

## Created Dockerfile – Ansible Master , ENTRYPOINT save id_rsa.pub in shared folder
docker run -d --name ansible-master-01 --network project-net -p 2222:22 -v ./.ssh_key/id_rsa:/home/ansible/.ssh/id_rsa  ansible-master-image

## Created Dockerfile – Ansible Slave  , ENTRYPOINT take from id_rsa.pub and move it to authorized_keys
docker run -d --name ansible-slave-01 --network project-net -p 2221:22 -v ./.ssh_key/id_rsa.pub:/home/ansible/.ssh/authorized_keys  ansible-slave-image

## Check access from master to slave
ansible -i ./ansible/inventory.yml slaves -m ping
ssh -i /home/ansible/.ssh/id_rsa ansible@ansible-slave-01

## Created Docker Compose – Ansible
docker compose -f ./ansible/docker-compose.yml up -d




make start-ansible - create images and up containers

docker tag  3d92e2da9dfc  evgenykorchev/ansible-slave-image:v01
docker push evgenykorchev/ansible-slave-image:v01

docker tag 17fcf297696f evgenykorchev/ansible-master-image:v01
docker push evgenykorchev/ansible-master-image:v01





Dockerfile – Application

Docker Compose – Application
Docker Compose – Database (PostgreSQL + pgAdmin)
Inventory file
Playbook – Installations
Playbook – Docker Compose deployment
README.md


docker build -t ansible-master-image -f ansible-master/Dockerfile .