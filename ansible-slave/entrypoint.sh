#!/bin/bash
chown -R ansible:ansible /home/ansible/.ssh
chmod 700 /home/ansible/.ssh
chmod 600 /home/ansible/.ssh/authorized_keys
chown root:root /etc/ssh/ssh_host_*
chmod 600 /etc/ssh/ssh_host_*

echo "ansible slave created..."
exec "$@"