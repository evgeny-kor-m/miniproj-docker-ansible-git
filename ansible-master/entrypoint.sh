#!/bin/bash
chown -R ansible:ansible /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/id_rsa
chmod 600 /home/ansible/.ssh/known_hosts
echo "ansible master created..."
exec "$@"