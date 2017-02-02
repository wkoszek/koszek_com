s:
	./start.sh
ve:
	@echo "editing vault"
	ansible-vault edit ./secrets.yml
