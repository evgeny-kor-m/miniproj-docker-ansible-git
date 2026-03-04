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
sudo mkdir ~/.ssh_key
sudo chown -R appuser:appuser ~/.ssh_key
sudo ssh-keygen -t rsa -b 4096 -f ~/.ssh_key/id_rsa -N ""
sudo mv ~/.ssh_key/id_rsa.pub ~/.ssh_key/authorized_keys

## Created Dockerfile – Ansible Master , ENTRYPOINT save id_rsa.pub in shared folder
docker run -d --name ansible-master-01 --network project-net -p 2222:22 -v ./.ssh_key/id_rsa:/home/ansible/.ssh/id_rsa  ansible-master-image

## Created Dockerfile – Ansible Slave  , ENTRYPOINT take from id_rsa.pub and move it to authorized_keys
docker run -d --name ansible-slave-01 --network project-net -p 2221:22 -v ./.ssh_key/authorized_keys:/home/ansible/.ssh/authorized_keys  ansible-slave-image

## Check access from master to slave
docker exec -it ansible-master-01 su - ansible
ansible -i /app/ansible/inventory.yml slaves -m ping
ssh -i /home/ansible/.ssh/id_rsa ansible@ansible-slave-01

## Created Docker Compose – Ansible
docker compose -f ./ansible/docker-compose.yml --env-file .env  up -d
make start-ansible - create images and up containers
make trust - Ssh-keyscan for slaves

## Push both images to DockerHub as Public repositories
docker tag  ansible-slave-image  evgenykorchev/ansible-slave-image:v01
docker push evgenykorchev/ansible-slave-image:v01

docker tag ansible-master-image evgenykorchev/ansible-master-image:v01
docker push evgenykorchev/ansible-master-image:v01




### Part 2
## Dockerfile – Application
python app/src/app_crm.py
docker rm -f app-crm && docker rmi -f app-crm-image

## Docker Compose – Application
docker compose --env-file .env -f ./app/docker-compose.yml up -d    --force-recreate

## Docker Compose – Database (PostgreSQL + pgAdmin)
https://github.com/docker-library/docs/blob/master/postgres/README.md#environment-variables

docker pull postgres
docker pull dpage/pgadmin4
docker compose --env-file .env -f ./database/docker-compose.yml up -d  --force-recreate
http://localhost:8080

localy:
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
docker exec postgresql cat /var/lib/postgresql/18/docker/pg_hba.conf  | tail -10
docker exec postgresql bash -c "echo 'host all all 0.0.0.0/0 md5' >> /var/lib/postgresql/18/docker/pg_hba.conf"
docker restart postgresql






## Inventory file
Playbook – Installations
Playbook – Docker Compose deployment
README.md


docker build -t ansible-master-image -f ansible-master/Dockerfile .