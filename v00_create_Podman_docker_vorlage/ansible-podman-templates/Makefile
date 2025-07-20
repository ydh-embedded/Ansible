# Makefile für Ansible Podman Container Projekte mit Health Dashboard

.PHONY: help install deploy destroy status login clean examples health dashboard monitor

# Variablen
PROJECT ?= mcp-server
EXTRA_VARS ?= 
ANSIBLE_DIR = ansible
PLAYBOOK = $(ANSIBLE_DIR)/site.yml

help: ## Zeige diese Hilfe
	@echo -e "\033[1;36m🐳 Ansible Podman Container Management\033[0m"
	@echo "Verfügbare Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $1, $2}'

install: ## Installiere Ansible und Dependencies
	@echo -e "\033[0;36m🔧 Installiere Ansible und Dependencies...\033[0m"
	@./show_progress.sh 3 "Installation läuft"
	@pip install ansible-core ansible-lint > /dev/null 2>&1 || echo "Ansible bereits installiert"
	@ansible-galaxy collection install containers.podman > /dev/null 2>&1 || echo "Podman Collection bereits installiert"
	@echo -e "\033[0;32m✅ Installation abgeschlossen\033[0m"

validate: ## Validiere Ansible-Konfiguration
	@echo -e "\033[0;36m🔍 Validiere Ansible-Konfiguration...\033[0m"
	@./show_progress.sh 2 "Validierung läuft"
	@cd $(ANSIBLE_DIR) && ansible-playbook --syntax-check $(PLAYBOOK) -e project_name=$(PROJECT)
	@echo -e "\033[0;32m✅ Validierung erfolgreich\033[0m"

deploy: ## Deploye Container-Projekt
	@echo -e "\033[0;36m🚀 Deploye Container-Projekt: $(PROJECT)\033[0m"
	@./show_progress.sh 5 "Deployment läuft"
	@cd $(ANSIBLE_DIR) && ansible-playbook $(PLAYBOOK) -e project_name=$(PROJECT) $(EXTRA_VARS)
	@echo -e "\033[0;32m✅ Deployment abgeschlossen\033[0m"

destroy: ## Entferne Container-Projekt
	@echo -e "\033[0;31m🗑️ Entferne Container-Projekt: $(PROJECT)\033[0m"
	@./show_progress.sh 3 "Entfernung läuft"
	@cd $(ANSIBLE_DIR) && ansible-playbook $(PLAYBOOK) -e project_name=$(PROJECT) -e container_state=absent $(EXTRA_VARS)

status: ## Zeige Projekt-Status
	@echo -e "\033[0;36m📊 Status für Projekt: $(PROJECT)\033[0m"
	@if [ -d "$HOME/ansible-projects/$(PROJECT)" ]; then \
		echo -e "\033[0;32m✅ Projekt existiert\033[0m"; \
		cd "$HOME/ansible-projects/$(PROJECT)" && ./manage.sh status 2>/dev/null || echo -e "\033[0;33m⚠️ Management-Script nicht verfügbar\033[0m"; \
	else \
		echo -e "\033[0;31m❌ Projekt nicht gefunden\033[0m"; \
	fi

health: ## Zeige Health Dashboard
	@./health-dashboard.sh

dashboard: ## Starte interaktives Dashboard
	@./health-dashboard.sh

monitor: ## Live Container Monitoring
	@echo -e "\033[0;36m📊 Starte Live-Monitoring (Ctrl+C zum Beenden)...\033[0m"
	@watch -c -n 5 'make status-all'

status-all: ## Zeige Status aller Projekte
	@echo -e "\033[1;36m📋 Alle Container-Projekte:\033[0m"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@for project in $(ls $HOME/ansible-projects/ 2>/dev/null || echo ""); do \
		if [ -n "$project" ]; then \
			container_name="$project-container"; \
			if podman ps --format "{{.Names}}" | grep -q "^$container_name$"; then \
				echo -e "  \033[0;32m✅ $project\033[0m - RUNNING"; \
			else \
				echo -e "  \033[0;31m❌ $project\033[0m - STOPPED"; \
			fi; \
		fi; \
	done

login: ## Logge in Container ein
	@echo -e "\033[0;36m🔐 Login in Container: $(PROJECT)\033[0m"
	@if [ -f "$HOME/ansible-projects/$(PROJECT)/login.sh" ]; then \
		cd "$HOME/ansible-projects/$(PROJECT)" && ./login.sh; \
	else \
		echo -e "\033[0;31m❌ Login-Script nicht gefunden. Erst deployen: make deploy PROJECT=$(PROJECT)\033[0m"; \
	fi

clean: ## Aufräumen
	@echo -e "\033[0;36m🧹 Räume auf...\033[0m"
	@./show_progress.sh 2 "Cleanup läuft"
	@podman system prune -f > /dev/null 2>&1
	@echo -e "\033[0;32m✅ Aufräumen abgeschlossen\033[0m"

list: ## Liste alle Projekte
	@echo -e "\033[0;36m📋 Verfügbare Projekte:\033[0m"
	@ls -la $HOME/ansible-projects/ 2>/dev/null || echo -e "\033[0;33mKeine Projekte gefunden\033[0m"

examples: ## Erstelle Beispiel-Projekte
	@echo -e "\033[0;36m📝 Erstelle Beispiel-Projekte...\033[0m"
	@./show_progress.sh 6 "Beispiele werden erstellt"
	@$(MAKE) deploy PROJECT=mcp-server > /dev/null 2>&1
	@$(MAKE) deploy PROJECT=web-app > /dev/null 2>&1
	@$(MAKE) deploy PROJECT=api-service > /dev/null 2>&1
	@echo -e "\033[0;32m✅ Beispiele erstellt\033[0m"

# Health-Check Targets
health-check: ## Führe Health-Check für alle Container durch
	@echo -e "\033[0;36m🏥 Health-Check läuft...\033[0m"
	@./show_progress.sh 3 "Scanning Container"
	@for project in $(ls $HOME/ansible-projects/ 2>/dev/null || echo ""); do \
		if [ -n "$project" ]; then \
			container_name="$project-container"; \
			if podman ps --format "{{.Names}}" | grep -q "^$container_name$"; then \
				health=$(podman inspect $container_name --format "{{.State.Health.Status}}" 2>/dev/null || echo "unknown"); \
				if [ "$health" = "healthy" ] || [ "$health" = "unknown" ]; then \
					echo -e "  \033[0;32m✅ $project\033[0m - $health"; \
				else \
					echo -e "  \033[0;31m❌ $project\033[0m - $health"; \
				fi; \
			fi; \
		fi; \
	done

web-status: ## Prüfe Web-Service Status
	@echo -e "\033[0;36m🌐 Web-Service Status:\033[0m"
	@for port in 6247 8501 8000 3000 8080; do \
		if timeout 2 bash -c "exec 6<>/dev/tcp/localhost/$port" 2>/dev/null; then \
			echo -e "  \033[0;32m✅ Port $port\033[0m - http://localhost:$port"; \
			exec 6>&-; \
		else \
			echo -e "  \033[0;31m❌ Port $port\033[0m - Service down"; \
		fi; \
	done

# Spezielle Targets für verschiedene Umgebungen
dev: ## Deploy in Development-Umgebung
	@$(MAKE) deploy PROJECT=$(PROJECT) EXTRA_VARS="-e environment=development"

prod: ## Deploy in Production-Umgebung
	@$(MAKE) deploy PROJECT=$(PROJECT) EXTRA_VARS="-e environment=production"

test: ## Teste Deployment
	@$(MAKE) validate
	@$(MAKE) deploy PROJECT=test-project EXTRA_VARS="-e container_config.ports=['9999:8080'] -e container_name=test-container"

# Batch-Operationen
start-all: ## Starte alle Container
	@echo -e "\033[0;36m🚀 Starte alle Container...\033[0m"
	@./show_progress.sh 4 "Container werden gestartet"
	@for project in $(ls $HOME/ansible-projects/ 2>/dev/null || echo ""); do \
		if [ -f "$HOME/ansible-projects/$project/manage.sh" ]; then \
			(cd "$HOME/ansible-projects/$project" && ./manage.sh start) & \
		fi; \
	done; wait
	@echo -e "\033[0;32m✅ Alle Container gestartet\033[0m"

stop-all: ## Stoppe alle Container
	@echo -e "\033[0;31m🛑 Stoppe alle Container...\033[0m"
	@./show_progress.sh 3 "Container werden gestoppt"
	@podman stop $(podman ps -q) 2>/dev/null || echo "Keine laufenden Container"
	@echo -e "\033[0;32m✅ Alle Container gestoppt\033[0m"

restart-all: ## Restart alle Container
	@$(MAKE) stop-all
	@sleep 2
	@$(MAKE) start-all

# Monitoring und Logs
logs: ## Zeige Container-Logs
	@echo -e "\033[0;36m📜 Container-Logs:\033[0m"
	@if [ "$(PROJECT)" != "mcp-server" ]; then \
		podman logs $(PROJECT)-container 2>/dev/null || echo "Container nicht gefunden"; \
	else \
		for project in $(ls $HOME/ansible-projects/ 2>/dev/null | head -3); do \
			echo -e "\033[1;36m📦 $project:\033[0m"; \
			podman logs --tail 5 "$project-container" 2>/dev/null || echo "Keine Logs"; \
			echo ""; \
		done; \
	fi

stats: ## Zeige Container-Statistiken
	@echo -e "\033[0;36m📊 Container-Statistiken:\033[0m"
	@podman stats --no-stream 2>/dev/null || echo "Keine laufenden Container"

# Utility Targets
show-urls: ## Zeige verfügbare URLs
	@echo -e "\033[0;36m🔗 Verfügbare URLs:\033[0m"
	@$(MAKE) web-status

open-browser: ## Öffne Browser mit aktiven Services
	@echo -e "\033[0;36m🌐 Öffne Browser...\033[0m"
	@for port in 6247 8501 8000 3000 8080; do \
		if timeout 1 bash -c "exec 6<>/dev/tcp/localhost/$port" 2>/dev/null; then \
			if command -v xdg-open >/dev/null 2>&1; then \
				xdg-open "http://localhost:$port" & \
			fi; \
			exec 6>&-; \
		fi; \
	done

backup: ## Backup Container Images
	@echo -e "\033[0;36m💾 Backup Container Images...\033[0m"
	@./show_progress.sh 4 "Backup läuft"
	@mkdir -p backups
	@for project in $(ls $HOME/ansible-projects/ 2>/dev/null || echo ""); do \
		if podman images | grep -q "$project"; then \
			podman save -o "backups/$project-$(date +%Y%m%d).tar" "$project:latest" 2>/dev/null || true; \
		fi; \
	done
	@echo -e "\033[0;32m✅ Backup abgeschlossen\033[0m"
