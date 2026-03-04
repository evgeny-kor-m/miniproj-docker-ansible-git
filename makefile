# Colors for output
GREEN = \033[0;32m
RED = \033[0;31m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m

ENV_FILE := .env
ANSIBLE_COMPOSE = ansible/docker-compose.yml

help: ## Show available commands and descriptions
	@echo "$(BLUE)Available commands:$(NC)"
	@grep -hE '^[a-zA-Z0-9_-]+:.*## ' $(MAKEFILE_LIST) \
	| awk 'BEGIN {FS=":.*## "}; {printf "  %-20s %s\n", $$1, $$2}'

prerequisite: ## Creating prerequisites
	docker network create project-net
	docker volume create shared-volume

clean: ## Remove test artifacts and cache
	@echo "$(YELLOW) Cleaning project folders...$(NC)"
	sudo find . -type d -name "__pycache__" -prune -exec rm -rf {} + || true
	find . -name "*.pyc" -delete
	@if [ -n "$$(docker ps -a -q)" ]; then \
		docker rm -f $$(docker ps -a -q); \
	fi
	@if [ -n "$$(@docker images -q)" ]; then \
		docker rmi -f $$(@docker images -q); \
	fi
	# docker images | grep -v ansible-slave-image | awk 'NR>1 {print $3}'
	@if [ -n "$$(docker volume ls -q)" ]; then \
		docker volume rm $$(docker volume ls -q);\
	fi
	docker system prune -a --volumes

start-ansible: ## Run tests in Docker
	@echo "$(BLUE) Running master/slave containers...$(NC)"
	@docker compose -f $(ANSIBLE_COMPOSE) --env-file $(ENV_FILE) up -d

stop-ansible: ## Run tests in Docker
	@echo "$(BLUE) Sopping master/slave containers...$(NC)"
	@docker compose -f $(ANSIBLE_COMPOSE) --env-file $(ENV_FILE) down

view: ## View resources
	@echo "$(BLUE) View images...$(NC)"
	docker images
	@echo "$(BLUE) View containers...$(NC)"
	docker ps -a
	@echo "$(BLUE) View networks...$(NC)"
	docker network ls
	@echo "$(BLUE) View volume...$(NC)"
	docker volume ls

full-ansible: ## Checking communication master/slave containers
	@echo "$(BLUE) Checking communication master/slave containers...$(NC)"
	@make prerequisite
	@make start-ansible
	@make trust
	@make check-access-from-master-to-slave

trust: ## Ssh-keyscan for slaves 
	docker exec -it ansible-master-01 sh -c "ssh-keyscan ansible-slave-01 >> /home/ansible/.ssh/known_hosts"

check-ansible: ## Test access from master to slave
	docker exec -it ansible-master-01 su - ansible sh -c "ansible -i /app/ansible/inventory.yml slaves -m ping"
	docker exec -it ansible-master-01 su - ansible bash -c  "ssh -i /home/ansible/.ssh/id_rsa ansible@ansible-slave-01 exit && echo 'SSH success'"

