#!/bin/bash


chown -R ansible:ansible /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/id_rsa


echo "creating mini-project"
mkdir -p /home/ansible/mini-project

ssh-keyscan -H github.com >> /home/ansible/.ssh/known_hosts
ssh-keyscan -H database-server >> /home/ansible/.ssh/known_hosts
ssh-keyscan -H application-server >> /home/ansible/.ssh/known_hosts

cat /home/ansible/.ssh/known_hosts

chmod 600 /home/ansible/.ssh/known_hosts

export GIT_SSH_COMMAND="ssh -i /home/ansible/.ssh/id_ed25519 -o StrictHostKeyChecking=no"

echo "Testing SSH connection to GitHub..."
ssh -T -i /home/ansible/.ssh/id_ed25519 -o StrictHostKeyChecking=no git@github.com || true

echo "Cloning repository $REPO_URL ..."
git clone $REPO_URL /home/ansible/mini-project

echo "Running install playbook..."
ansible-playbook -i /home/ansible/mini-project/ansible/inventory.yml  /home/ansible/mini-project/ansible/playbook-installation.yml

echo "Running deploy playbook..."
ansible-playbook -i /home/ansible/mini-project/ansible/inventory.yml  /home/ansible/mini-project/ansible/playbook-deploy.yml


chmod 600 /home/ansible/.ssh/known_hosts
echo "ansible master created..."
exec "$@"