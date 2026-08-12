#!/bin/bash
set -e

echo "Setting up SSH..."
chown -R ansible:ansible /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/id_rsa
chmod 600 /home/ansible/.ssh/id_ed25519

echo "Adding hosts to known_hosts..."
su - ansible -c "ssh-keyscan -H github.com          >> /home/ansible/.ssh/known_hosts"
su - ansible -c "ssh-keyscan -H database-server     >> /home/ansible/.ssh/known_hosts"
su - ansible -c "ssh-keyscan -H application-server  >> /home/ansible/.ssh/known_hosts"
chmod 600 /home/ansible/.ssh/known_hosts

export GIT_SSH_COMMAND="ssh -i /home/ansible/.ssh/id_ed25519 -o StrictHostKeyChecking=no"

echo "Testing SSH connection to GitHub..."
ssh -T -i /home/ansible/.ssh/id_ed25519 -o StrictHostKeyChecking=no git@github.com || true

echo "Cloning repository $REPO_URL ..."
git clone -b ${REPO_BRANCH:-worker} $REPO_URL /home/ansible/mini-project
chown -R ansible:ansible /home/ansible/mini-project

echo "Running install playbook..."
su - ansible -c "ansible-playbook \
  -i /home/ansible/mini-project/ansible/inventory.yml \
     /home/ansible/mini-project/ansible/playbook-installation.yml"

echo "Running deploy playbook..."
su - ansible -c "ansible-playbook \
  -i /home/ansible/mini-project/ansible/inventory.yml \
     /home/ansible/mini-project/ansible/playbook-deploy.yml"

echo "Running firewall playbook..."
su - ansible -c "ansible-playbook \
  -i /home/ansible/mini-project/ansible/inventory.yml \
     /home/ansible/mini-project/ansible/playbook-firewall.yml"

echo "Ansible servers are ready."
exec "$@"