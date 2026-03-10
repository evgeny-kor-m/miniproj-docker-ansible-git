# mini-project

### Part 1

## Created a Private Repository житч README file - mini-project
git clone https://github.com/evgeny-kor-m/mini-project.git
git branch worker
git checkout worker
git branch

nano ~/.docker/config.json -> {   "auths": {}  }  - Connects Docker running in console to Windows Credential Manager.

Created Makefile
```
make clean - remove all (images, containers, volumes, net)
make prerequisite - create net, volume
```

## Create ssh_key folder and generate key
mkdir ~/.ssh_key
mkdir -p ~/.ssh_key/etc/ssh
ssh-keygen -A -f ~/.ssh_key
ssh-keygen -t rsa -b 4096 -f ~/.ssh_key/id_rsa -N ""
mv ~/.ssh_key/id_rsa.pub ~/.ssh_key/authorized_keys
ssh-keygen -t ed25519 -C "ansible-deploy" -f ~/.ssh_key/github_deploy_key -N ""
mv ~/.ssh_key/github_deploy_key ~/.ssh_key/id_ed25519
cat github_deploy_key.pub            ### Repository → Settings → Deploy keys → Add deploy key
touch ~/.ssh_key/master_known_hosts
ssh-keyscan -t rsa github.com > ~/.ssh_key/slave_known_hosts
sudo chown -R appuser:appuser ~/.ssh_key
chmod 700 ~/.ssh_key
chmod 644 ~/.ssh_key/*.pub ~/.ssh_key/slave_known_hosts ~/.ssh_key/master_known_hosts
chmod 600 ~/.ssh_key/etc/ssh/ssh_host_rsa_key
chmod 600 ~/.ssh_key/etc/ssh/ssh_host_ed25519_key
chmod 600 ~/.ssh_key/*



## -- next time cp -r shared-folder/.shh_key/ ~/.ssh_key && 
chmod 600 known_hosts
sudo chown -R appuser:appuser ~/.ssh_key

## Created Dockerfile – Ansible Master 
docker run -d --name ansible-master-01 \
    --network project-net -p 2222:22 \
    -v ~/.ssh_key/master_known_hosts:/home/ansible/.ssh/known_hosts \
    -v ~/.ssh_key/id_rsa:/home/ansible/.ssh/id_rsa \
    ansible-master-image

## Created Dockerfile – Ansible Slave  , ENTRYPOINT take from id_rsa.pub and move it to authorized_keys
docker run -d --name ansible-slave-01 \
    --network project-net -p 2221:22 \
    -v ~/.ssh_key/authorized_keys:/home/ansible/.ssh/authorized_keys \
    -v ~/.ssh_key/slave_known_hosts:/home/ansible/.ssh/known_hosts \
    -v ~/.ssh_key/id_ed25519:/home/ansible/.ssh/id_ed25519 \    
     ansible-slave-image

## Check access from master to slave
docker exec -it ansible-master-01 su - ansible
ssh-keyscan -t rsa ansible-slave-01 >> /home/ansible/.ssh/known_hosts
ansible -i /app/ansible/inventory.yml slaves -m ping
ssh -i /home/ansible/.ssh/id_rsa ansible@ansible-slave-01

## Created Docker Compose – Ansible
docker compose -f ./ansible/docker-compose.yml --env-file .env  up -d
docker compose -f ./ansible/docker-compose.yml --env-file .env  build
make start-ansible - create images and up containers
make trust - Ssh-keyscan for slaves

## Push both images to DockerHub as Public repositories
docker tag  ansible-slave-image  evgenykorchev/ansible-slave-image:v02
docker push evgenykorchev/ansible-slave-image:v02

docker tag ansible-master-image evgenykorchev/ansible-master-image:v02
docker push evgenykorchev/ansible-master-image:v02




### Part 2
## Dockerfile – Application
python app/src/app_crm.py
docker rm -f app-crm && docker rmi -f app-crm-image
http://127.0.0.1:5000/healthcheck

## Docker Compose – Application
docker compose --env-file .env -f ./app/docker-compose.yml up -d    --force-recreate



## Docker Compose – Database (PostgreSQL + pgAdmin)
PostgreSQL
https://github.com/docker-library/docs/blob/master/postgres/README.md#environment-variables

docker pull postgres
docker pull dpage/pgadmin4
docker compose --env-file .env -f ./database/docker-compose.yml up -d  --force-recreate
docker exec -it postgresql psql -U postgres

docker rm -f postgresql && docker volume rm shared-volume

docker run --name postgresql -d -p 5433:5432  \
               --network=project-net \
               -e POSTGRES_PASSWORD=postgresdb \
               -v shared-volume:/var/lib/postgresql postgres

docker exec -it postgresql psql -U postgres -c "CREATE DATABASE mydb;"
docker exec -it postgresql psql -U postgres -c "CREATE USER myuser WITH PASSWORD 'mypass123';"
docker exec -it postgresql psql -U postgres -c "GRANT ALL ON DATABASE mydb TO myuser;"
docker exec -it postgresql psql -U postgres -d mydb -c "GRANT ALL ON SCHEMA public TO myuser;"

docker exec postgresql env | grep POSTGRES
-- openning access to postgres from all IP address (from HOST)
    docker exec postgresql cat /var/lib/postgresql/18/docker/pg_hba.conf  | tail -10
    docker exec postgresql bash -c "echo 'host all all 0.0.0.0/0 md5' >> /var/lib/postgresql/18/docker/pg_hba.conf"
    docker restart postgresql

pgAdmin
http://localhost:8080
polzovatel@gmail.com/pass



## Inventory file: done
## Playbook – Installations






Playbook – Docker Compose deployment
README.md


## Common docker compose


docker compose --env-file .env up -d       ## --force-recreate
docker exec -it master-server su - ansible
# Example of restarting your container with the required privileges
docker run -d --privileged --name database-server -v /var/lib/docker:/var/lib/docker ubuntu:latest


ansible -i /app/ansible/final-inventory.yml slaves -m ping
ansible-playbook -i /app/ansible/final-inventory.yml /app/ansible/playbook-installation.yml --syntax-check
ansible-playbook -i /app/ansible/final-inventory.yml /app/ansible/deploy.yml

ssh -i /home/ansible/.ssh/id_rsa ansible@database-server
ssh -i /home/ansible/.ssh/id_rsa ansible@application-server

docker exec -it database-server su - ansible

