#!/bin/bash
mv /home/ansible/.ssh/id_rsa.pub /home/ansible/.ssh/authorized_keys 
mv /home/ansible/.ssh/id_rsa /var/shared 
exec "$@"