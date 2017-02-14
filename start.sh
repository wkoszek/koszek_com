#!/bin/sh

export ANSIBLE_VAULT_PASSWORD_FILE=`pwd`/scripts/ansible-lastpass.sh

ANSIBLE_OPTS=
if [ "$1" = "-v" ]; then
	ANSIBLE_OPTS=-vvvv # verbose
fi

IP=`cat IP`

ssh root@${IP} apt-get install -y python letsencrypt
cat files/root/renew.sh | ssh root@${IP} /bin/sh
ansible ${ANSIBLE_OPTS} -u root -i ${IP}, all -m ping
ansible-playbook -i ${IP}, playbook.yml
