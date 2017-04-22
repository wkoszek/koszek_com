export ANSIBLE_VAULT_PASSWORD_FILE=$(shell command -v lastpass-ansible)

s:
	./start.sh
ve:
	@echo "editing vault"
	ansible-vault edit ./secrets.yml
ssh:
	ssh root@`cat IP`
sync:
	rsync -va --delete --exclude '*\.git' ../me/build/ root@`cat IP`:/var/www/koszek.com/
revsync:
	mkdir -p files_rev/
	rsync -va --exclude '*\.git' root@`cat IP`:/etc files_rev/
clean:
	rm -rf playbook.retry
