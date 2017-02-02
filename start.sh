#!/bin/sh

ANSIBLE_OPTS=
if [ "$1" = "-v" ]; then
	ANSIBLE_OPTS=-vvvv # verbose
fi

ssh root@138.68.197.86 apt-get install -y python
ansible ${ANSIBLE_OPTS} -i inventory all -m ping 
ansible-playbook -i inventory playbook.yml
