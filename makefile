s:
	./start.sh
ve:
	@echo "editing vault"
	ansible-vault edit ./secrets.yml
ssh:
	ssh root@`cat IP`
sync:
	rsync -va --delete --exclude '*\.git' ../me/build/ root@`cat IP`:/var/www/koszek.com/
clean:
	rm -rf playbook.retry
