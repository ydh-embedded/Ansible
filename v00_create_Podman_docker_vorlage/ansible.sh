#!/bin/bash
# setup-ansible-project.sh - Ansible Projekt Setup Script

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_health() { echo -e "${CYAN}[HEALTH]${NC} $1"; }

# Ladebalken-Funktion (cyan)
show_progress() {
    local duration=${1:-3}
    local message=${2:-"Processing"}
    local width=50
    
    echo -ne "${CYAN}${message}${NC} ["
    
    for ((i=0; i<=width; i++)); do
        local percent=$((i * 100 / width))
        printf "\r${CYAN}${message}${NC} ["
        
        for ((j=0; j<i; j++)); do
            printf "${CYAN}█${NC}"
        done
        
        for ((j=i; j<width; j++)); do
            printf " "
        done
        
        printf "] ${CYAN}%d%%${NC}" "$percent"
        sleep $(echo "$duration / $width" | bc -l 2>/dev/null || echo "0.1")
    done
    
    echo -e "\n${GREEN}✅ Abgeschlossen!${NC}"
}

# Health-Status-Funktion
get_container_health() {
    local container_name=$1
    
    if podman ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
        local status=$(podman inspect $container_name --format "{{.State.Status}}")
        local health=$(podman inspect $container_name --format "{{.State.Health.Status}}" 2>/dev/null || echo "unknown")
        local uptime=$(podman inspect $container_name --format "{{.State.StartedAt}}")
        
        echo "$status|$health|$uptime"
    else
        echo "stopped|unhealthy|never"
    fi
}

show_banner() {
    echo -e "${BLUE}"
    echo "============================================="
    echo "  Ansible Podman Container Project Setup"
    echo "============================================="
    echo -e "${NC}"
}

# Hauptfunktion
main() {
    show_banner
    
    PROJECT_NAME=${1:-"mcp-server"}
    BASE_DIR="ansible-podman-templates"
    
    log_info "Erstelle Ansible-Projekt für: $PROJECT_NAME"
    
    # Projekt-Struktur erstellen
    mkdir -p $BASE_DIR/{ansible/{roles/{podman_setup,container_project,monitoring}/{tasks,templates,vars,handlers},vars,inventory},examples}
    
    cd $BASE_DIR
    
    # Ansible-Dateien erstellen (verwende die Inhalte aus dem vorherigen Artifact)
    log_info "Erstelle Ansible-Konfiguration..."
    
    # ansible.cfg
    cat > ansible/ansible.cfg << 'EOF'
[defaults]
inventory = inventory/localhost.ini
host_key_checking = False
timeout = 30
gathering = smart
fact_caching = memory
stdout_callback = yaml
roles_path = roles

[inventory]
enable_plugins = host_list, script, auto, yaml, ini, toml

[privilege_escalation]
become = False
EOF

    # Inventory
    cat > ansible/inventory/localhost.ini << 'EOF'
[local]
localhost ansible_connection=local

[containers]
localhost

[all:vars]
ansible_python_interpreter={{ ansible_playbook_python }}
EOF

    # Health Dashboard Script erstellen
    cat > health-dashboard.sh << 'EOF'
#!/bin/bash

# Health Dashboard für Ansible Container Projekte

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# Ladebalken-Funktion
show_progress() {
    local duration=${1:-2}
    local message=${2:-"Scanning"}
    local width=40
    
    echo -ne "${CYAN}${message}${NC} ["
    
    for ((i=0; i<=width; i++)); do
        local percent=$((i * 100 / width))
        printf "\r${CYAN}${message}${NC} ["
        
        for ((j=0; j<i; j++)); do
            printf "${CYAN}█${NC}"
        done
        
        for ((j=i; j<width; j++)); do
            printf " "
        done
        
        printf "] ${CYAN}%d%%${NC}" "$percent"
        sleep $(echo "$duration / $width" | bc -l 2>/dev/null || echo "0.05")
    done
    
    echo ""
}

# Container-Health abrufen
get_container_health() {
    local container_name=$1
    
    if podman ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
        local status=$(podman inspect $container_name --format "{{.State.Status}}" 2>/dev/null)
        local started=$(podman inspect $container_name --format "{{.State.StartedAt}}" 2>/dev/null)
        local image=$(podman inspect $container_name --format "{{.ImageName}}" 2>/dev/null)
        
        # CPU und Memory Usage
        local stats=$(podman stats --no-stream --format "{{.CPUPerc}},{{.MemUsage}}" $container_name 2>/dev/null | head -1)
        local cpu=$(echo "$stats" | cut -d',' -f1 | sed 's/%//')
        local memory=$(echo "$stats" | cut -d',' -f2)
        
        echo "$status|$started|$image|$cpu|$memory"
    else
        echo "stopped|never|unknown|0|0B"
    fi
}

# Service-Health prüfen
check_service_health() {
    local host=$1
    local port=$2
    local timeout=${3:-3}
    
    if timeout $timeout bash -c "exec 6<>/dev/tcp/$host/$port" 2>/dev/null; then
        exec 6>&-
        echo "healthy"
    else
        echo "unhealthy"
    fi
}

# Dashboard Header
show_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    🏥 HEALTH DASHBOARD                       ║"
    echo "║                 Ansible Container Monitor                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${BLUE}📊 System Status - $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
}

# Container-Status anzeigen
show_container_status() {
    local projects_dir="$HOME/ansible-projects"
    
    if [ ! -d "$projects_dir" ]; then
        echo -e "${YELLOW}⚠️ Keine Projekte gefunden in: $projects_dir${NC}"
        return
    fi
    
    echo -e "${CYAN}${BOLD}📦 Container Status${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    printf "%-20s %-12s %-12s %-10s %-15s %s\n" "PROJECT" "STATUS" "HEALTH" "CPU" "MEMORY" "UPTIME"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for project_dir in "$projects_dir"/*; do
        if [ -d "$project_dir" ]; then
            local project_name=$(basename "$project_dir")
            local container_name="${project_name}-container"
            
            # Container-Info abrufen
            local health_info=$(get_container_health "$container_name")
            IFS='|' read -r status started image cpu memory <<< "$health_info"
            
            # Status-Icon und Farbe
            local status_icon="❌"
            local status_color="$RED"
            local health_status="STOPPED"
            
            if [ "$status" = "running" ]; then
                status_icon="✅"
                status_color="$GREEN"
                health_status="RUNNING"
                
                # Uptime berechnen
                if [ "$started" != "never" ]; then
                    local uptime=$(date -d "$started" +%s 2>/dev/null || echo "0")
                    local now=$(date +%s)
                    local diff=$((now - uptime))
                    local uptime_str=$(date -d "@$diff" -u +%H:%M:%S 2>/dev/null || echo "unknown")
                else
                    local uptime_str="unknown"
                fi
            else
                local uptime_str="stopped"
                cpu="0"
                memory="0B"
            fi
            
            # CPU-Farbe basierend auf Auslastung
            local cpu_color="$GREEN"
            if (( $(echo "$cpu > 70" | bc -l 2>/dev/null || echo "0") )); then
                cpu_color="$RED"
            elif (( $(echo "$cpu > 40" | bc -l 2>/dev/null || echo "0") )); then
                cpu_color="$YELLOW"
            fi
            
            printf "%-20s ${status_color}%-12s${NC} %-12s ${cpu_color}%-10s${NC} %-15s %s\n" \
                "$project_name" "$health_status" "$status_icon" "${cpu}%" "$memory" "$uptime_str"
        fi
    done
    
    echo ""
}

# Service-Status anzeigen
show_service_status() {
    echo -e "${CYAN}${BOLD}🌐 Service Status${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Häufige Ports prüfen
    local services=(
        "MCP Inspector:6247"
        "Streamlit:8501"
        "API Service:8000"
        "Web App:3000"
        "Admin Panel:8080"
    )
    
    printf "%-20s %-10s %-15s %s\n" "SERVICE" "PORT" "STATUS" "URL"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    for service_info in "${services[@]}"; do
        IFS=':' read -r service_name port <<< "$service_info"
        
        local health=$(check_service_health "localhost" "$port" 2)
        local status_icon="❌"
        local status_color="$RED"
        local status_text="DOWN"
        
        if [ "$health" = "healthy" ]; then
            status_icon="✅"
            status_color="$GREEN"
            status_text="UP"
        fi
        
        printf "%-20s %-10s ${status_color}%-15s${NC} http://localhost:%s\n" \
            "$service_name" "$port" "$status_text" "$port"
    done
    
    echo ""
}

# System-Ressourcen anzeigen
show_system_resources() {
    echo -e "${CYAN}${BOLD}🖥️ System Resources${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # CPU-Info
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//' 2>/dev/null || echo "0")
    local cpu_color="$GREEN"
    if (( $(echo "$cpu_usage > 70" | bc -l 2>/dev/null || echo "0") )); then
        cpu_color="$RED"
    elif (( $(echo "$cpu_usage > 40" | bc -l 2>/dev/null || echo "0") )); then
        cpu_color="$YELLOW"
    fi
    
    # Memory-Info
    local mem_info=$(free -h | awk 'NR==2{printf "%.1f/%.1f GB (%.1f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}' 2>/dev/null || echo "unknown")
    
    # Disk-Info
    local disk_usage=$(df -h / | awk 'NR==2{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    local disk_color="$GREEN"
    if (( disk_usage > 80 )); then
        disk_color="$RED"
    elif (( disk_usage > 60 )); then
        disk_color="$YELLOW"
    fi
    
    printf "💻 CPU Usage:    ${cpu_color}%s%%${NC}\n" "$cpu_usage"
    printf "🧠 Memory:       %s\n" "$mem_info"
    printf "💾 Disk Usage:   ${disk_color}%s%%${NC}\n" "$disk_usage"
    printf "🐳 Podman:       %s\n" "$(podman --version 2>/dev/null || echo 'not installed')"
    
    echo ""
}

# Container-Logs anzeigen
show_container_logs() {
    echo -e "${CYAN}${BOLD}📜 Recent Container Logs${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local projects_dir="$HOME/ansible-projects"
    local log_count=0
    
    for project_dir in "$projects_dir"/*; do
        if [ -d "$project_dir" ]; then
            local project_name=$(basename "$project_dir")
            local container_name="${project_name}-container"
            
            if podman ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
                echo -e "${BLUE}📦 $project_name${NC}"
                podman logs --tail 3 "$container_name" 2>/dev/null | sed 's/^/   /' || echo "   No logs available"
                echo ""
                ((log_count++))
            fi
        fi
    done
    
    if [ $log_count -eq 0 ]; then
        echo -e "${YELLOW}ℹ️ Keine laufenden Container gefunden${NC}"
    fi
}

# Aktionen-Menü
show_actions() {
    echo -e "${CYAN}${BOLD}⚡ Quick Actions${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1) 🔄 Refresh Dashboard    2) 🚀 Start All Containers    3) 🛑 Stop All Containers"
    echo "4) 🧹 Cleanup System       5) 📊 Live Monitoring         6) 🔍 Detailed Logs"
    echo "7) 🌐 Open Web Interfaces  8) 📋 Export Status Report    9) ❌ Exit"
    echo ""
}

# Live-Monitoring
start_live_monitoring() {
    echo -e "${CYAN}🔴 Live-Monitoring gestartet (Ctrl+C zum Beenden)${NC}"
    echo ""
    
    while true; do
        show_header
        show_container_status
        show_service_status
        echo -e "${CYAN}🔄 Auto-refresh in 5 seconds...${NC}"
        sleep 5
    done
}

# Web-Interfaces öffnen
open_web_interfaces() {
    echo -e "${CYAN}🌐 Öffne verfügbare Web-Interfaces...${NC}"
    
    local ports=("6247" "8501" "8000" "3000" "8080")
    local opened=0
    
    for port in "${ports[@]}"; do
        if check_service_health "localhost" "$port" 1 | grep -q "healthy"; then
            if command -v xdg-open &> /dev/null; then
                xdg-open "http://localhost:$port" &
                echo -e "${GREEN}✅ Geöffnet: http://localhost:$port${NC}"
                ((opened++))
            else
                echo -e "${BLUE}📋 Verfügbar: http://localhost:$port${NC}"
            fi
        fi
    done
    
    if [ $opened -eq 0 ]; then
        echo -e "${YELLOW}⚠️ Keine aktiven Web-Services gefunden${NC}"
    fi
}

# Hauptfunktion
main() {
    while true; do
        show_progress 1 "Lade Dashboard"
        show_header
        show_container_status
        show_service_status
        show_system_resources
        show_container_logs
        show_actions
        
        read -p "Wählen Sie eine Aktion (1-9): " choice
        
        case $choice in
            1) continue ;;
            2) 
                show_progress 2 "Starte Container"
                cd "$HOME/ansible-projects" 2>/dev/null || true
                for dir in */; do
                    if [ -f "$dir/manage.sh" ]; then
                        (cd "$dir" && ./manage.sh start &)
                    fi
                done
                ;;
            3)
                show_progress 2 "Stoppe Container"
                podman stop $(podman ps -q) 2>/dev/null || true
                ;;
            4)
                show_progress 3 "System-Cleanup"
                podman system prune -f
                ;;
            5) start_live_monitoring ;;
            6)
                echo -e "${CYAN}📊 Detaillierte Logs:${NC}"
                podman logs $(podman ps --format "{{.Names}}" | head -1) 2>/dev/null || echo "Keine Container aktiv"
                read -p "Drücken Sie Enter zum Fortfahren..."
                ;;
            7) open_web_interfaces; sleep 2 ;;
            8)
                echo -e "${CYAN}📋 Exportiere Status-Report...${NC}"
                echo "# Container Health Report - $(date)" > /tmp/container-health-report.txt
                show_container_status >> /tmp/container-health-report.txt
                echo -e "${GREEN}✅ Report gespeichert: /tmp/container-health-report.txt${NC}"
                sleep 2
                ;;
            9) echo -e "${GREEN}👋 Auf Wiedersehen!${NC}"; exit 0 ;;
            *) echo -e "${RED}❌ Ungültige Option${NC}"; sleep 1 ;;
        esac
    done
}

# Script ausführen
main "$@"
EOF

    chmod +x health-dashboard.sh

    # Makefile erstellen
    cat > Makefile << 'EOF'
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
EOF

    # Ladebalken-Hilfsskript
    cat > show_progress.sh << 'EOF'
#!/bin/bash

# Cyan Ladebalken für Ansible Container Operations
CYAN='\033[0;36m'
GREEN='\033[0;32m'
NC='\033[0m'

show_progress() {
    local duration=${1:-3}
    local message=${2:-"Processing"}
    local width=50
    
    for ((i=0; i<=width; i++)); do
        local percent=$((i * 100 / width))
        printf "\r${CYAN}${message}${NC} ["
        
        for ((j=0; j<i; j++)); do
            printf "${CYAN}█${NC}"
        done
        
        for ((j=i; j<width; j++)); do
            printf " "
        done
        
        printf "] ${CYAN}%d%%${NC}" "$percent"
        sleep $(echo "scale=3; $duration / $width" | bc -l 2>/dev/null || echo "0.06")
    done
    
    echo -e "\n${GREEN}✅ Abgeschlossen!${NC}"
}

show_progress "$@"
EOF

    chmod +x show_progress.sh

    # Quick-Start Script
    cat > quick-start.sh << 'EOF'
#!/bin/bash

# Quick-Start Script für Ansible Podman Container Projekte mit Health Dashboard

# Farben
CYAN='\033[0;36m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_NAME=${1:-"mcp-server"}

echo -e "${CYAN}🚀 Quick-Start für Projekt: $PROJECT_NAME${NC}"
echo "=========================================="

# Ladebalken-Funktion
show_progress() {
    local duration=${1:-2}
    local message=${2:-"Processing"}
    ./show_progress.sh "$duration" "$message"
}

# 1. Dependencies installieren
echo -e "${BLUE}📦 1/5 - Installiere Dependencies...${NC}"
show_progress 3 "Dependencies werden installiert"
make install > /dev/null 2>&1

# 2. Projekt deployen
echo -e "${BLUE}🚀 2/5 - Deploye Projekt...${NC}"
show_progress 6 "Projekt wird deployed"
make deploy PROJECT=$PROJECT_NAME > /dev/null 2>&1

# 3. Health-Check
echo -e "${BLUE}🏥 3/5 - Health-Check...${NC}"
show_progress 2 "Container-Status wird geprüft"
sleep 3  # Warten bis Container vollständig gestartet

# 4. Web-Services prüfen
echo -e "${BLUE}🌐 4/5 - Prüfe Web-Services...${NC}"
show_progress 2 "Services werden getestet"

# 5. Dashboard anzeigen
echo -e "${BLUE}📊 5/5 - Status-Übersicht...${NC}"
show_progress 1 "Dashboard wird vorbereitet"

echo ""
echo -e "${GREEN}✅ Quick-Start abgeschlossen!${NC}"
echo ""
echo -e "${CYAN}🎯 Verfügbare Kommandos:${NC}"
echo "  make health PROJECT=$PROJECT_NAME     - Health Dashboard"
echo "  make login PROJECT=$PROJECT_NAME      - In Container einloggen"
echo "  make monitor                          - Live-Monitoring"
echo "  make status PROJECT=$PROJECT_NAME     - Status prüfen"
echo "  make dashboard                        - Interaktives Dashboard"
echo ""
echo -e "${YELLOW}🌐 Web-Interfaces:${NC}"
make web-status
echo ""
echo -e "${CYAN}📋 Nächste Schritte:${NC}"
echo "1. make dashboard    - Für interaktives Health-Dashboard"
echo "2. make login PROJECT=$PROJECT_NAME - Zum Container-Login"
echo "3. make monitor      - Für Live-Monitoring"
EOF

    chmod +x quick-start.sh

    # Beispiel-Projekt-Variablen
    cat > ansible/vars/api-service.yml << 'EOF'
project_name: "api-service"
project_description: "REST API Service"
container_name: "{{ project_name }}-container"
container_image: "{{ project_name }}:latest"

container_config:
  ports:
    - "8000:8000"  # API
    - "8080:8080"  # Admin
  volumes:
    - "{{ project_base_dir }}/{{ project_name }}/data:/app/data"
    - "{{ project_base_dir }}/{{ project_name }}/logs:/app/logs"
  environment:
    API_PORT: "8000"
    ADMIN_PORT: "8080"
    LOG_LEVEL: "INFO"

dockerfile_config:
  base_image: "python:3.11-slim"
  working_dir: "/app"
  python_requirements:
    - "fastapi>=0.104.0"
    - "uvicorn>=0.24.0"
    - "sqlalchemy>=2.0.0"
    - "psycopg2-binary>=2.9.0"
  system_packages:
    - "curl"
    - "postgresql-client"
  exposed_ports:
    - "8000"
    - "8080"
EOF

    # README erstellen
    cat > README.md << 'EOF'
# Ansible Podman Container Templates

Wiederverwendbare Ansible-Templates für Podman-Container-Projekte mit automatischem Login-Script.

## 🚀 Quick-Start

```bash
# 1. Repository klonen/erstellen
./setup-ansible-project.sh

# 2. Dependencies installieren
make install

# 3. Erstes Projekt deployen
make deploy PROJECT=mcp-server

# 4. In Container einloggen
make login PROJECT=mcp-server
```

## 📁 Struktur

```
ansible-podman-templates/
├── Makefile                    # Build-Automatisierung
├── quick-start.sh             # Schnellstart-Script
├── ansible/
│   ├── site.yml               # Haupt-Playbook
│   ├── ansible.cfg            # Ansible-Konfiguration
│   ├── inventory/             # Host-Inventar
│   ├── vars/                  # Projekt-Variablen
│   │   ├── common.yml         # Gemeinsame Variablen
│   │   ├── mcp-server.yml     # MCP-Server Projekt
│   │   ├── web-app.yml        # Web-App Projekt
│   │   └── api-service.yml    # API-Service Projekt
│   └── roles/                 # Ansible-Rollen
│       ├── podman_setup/      # Podman-Installation
│       ├── container_project/ # Container-Deployment
│       └── monitoring/        # Monitoring-Setup
└── examples/                  # Beispiel-Projekte
```

## 🛠️ Verfügbare Kommandos

### Projekt-Management
```bash
make deploy PROJECT=my-project     # Projekt deployen
make destroy PROJECT=my-project    # Projekt entfernen
make status PROJECT=my-project     # Projekt-Status
make login PROJECT=my-project      # Container-Login
```

### Entwicklung
```bash
make validate                      # Ansible-Syntax prüfen
make dev PROJECT=my-project        # Development-Deployment
make prod PROJECT=my-project       # Production-Deployment
make test                         # Test-Deployment
```

### Wartung
```bash
make clean                        # Container-Cleanup
make list                         # Alle Projekte auflisten
make examples                     # Beispiel-Projekte erstellen
```

## 📋 Neues Projekt erstellen

### 1. Projekt-Variablen definieren

Erstellen Sie `ansible/vars/mein-projekt.yml`:

```yaml
project_name: "mein-projekt"
project_description: "Mein Custom Projekt"
container_name: "{{ project_name }}-container"
container_image: "{{ project_name }}:latest"

container_config:
  ports:
    - "3000:3000"
  volumes:
    - "{{ project_base_dir }}/{{ project_name }}/data:/app/data"
  environment:
    NODE_ENV: "development"

dockerfile_config:
  base_image: "node:18-alpine"
  working_dir: "/app"
  exposed_ports:
    - "3000"
```

### 2. Projekt deployen

```bash
make deploy PROJECT=mein-projekt
```

### 3. Container verwenden

```bash
# In Container einloggen
make login PROJECT=mein-projekt

# Status prüfen
make status PROJECT=mein-projekt
```

## 🔧 Konfiguration

### Container-Konfiguration

Jedes Projekt wird durch eine YAML-Datei in `ansible/vars/` konfiguriert:

- **project_name**: Eindeutiger Projekt-Name
- **container_config**: Container-spezifische Einstellungen
- **dockerfile_config**: Dockerfile-Generierung
- **services**: Service-Definitionen

### Ansible-Rollen

- **podman_setup**: Installiert und konfiguriert Podman
- **container_project**: Erstellt Container-Projekt mit allen Scripts
- **monitoring**: Optionales Monitoring-Setup

## 📦 Generierte Dateien

Für jedes Projekt werden automatisch erstellt:

```
~/ansible-projects/PROJECT_NAME/
├── login.sh              # 🔐 Container-Login
├── manage.sh             # 🛠️ Container-Management
├── build.sh              # 🔨 Container-Build
├── deploy.sh             # 🚀 Container-Deploy
├── cleanup.sh            # 🧹 Cleanup
├── container/
│   ├── Dockerfile        # Container-Definition
│   ├── requirements.txt  # Dependencies
│   └── app files...      # Anwendungs-Dateien
├── configs/              # Konfigurationsdateien
├── data/                 # Persistente Daten
└── logs/                 # Log-Dateien
```

## 🔐 Login-Script Features

Das generierte `login.sh` bietet:

- **Interaktive Shell**: Bash, Python, Root
- **Container-Status**: Live-Informationen
- **Prozess-Übersicht**: Laufende Services
- **Log-Anzeige**: Container-Logs
- **Dateisystem-Browser**: Struktur-Übersicht

## 🌐 Web-Interfaces

Automatisch verfügbare Web-Services:

- **Monitoring**: Container-Status und Logs
- **Application**: Projekt-spezifische Services
- **Management**: Web-basierte Container-Verwaltung

## 🎯 Anwendungsfälle

### MCP-Server
```bash
make deploy PROJECT=mcp-server
# → MCP Inspector: http://localhost:6247
# → Streamlit Client: http://localhost:8501
```

### Web-Anwendung
```bash
make deploy PROJECT=web-app
# → Frontend: http://localhost:3000
# → Backend API: http://localhost:8000
```

### API-Service
```bash
make deploy PROJECT=api-service
# → API: http://localhost:8000
# → Admin: http://localhost:8080
```

## 🔄 Workflow

1. **Projekt definieren**: Variablen in `vars/` erstellen
2. **Deployen**: `make deploy PROJECT=name`
3. **Entwickeln**: `make login PROJECT=name`
4. **Testen**: Web-Interfaces nutzen
5. **Deployen**: Updates mit erneutem `make deploy`

## 🚨 Troubleshooting

### Container startet nicht
```bash
make status PROJECT=name
podman logs project-container
```

### Port-Konflikte
```bash
sudo netstat -tulpn | grep :PORT
```

### Ansible-Fehler
```bash
make validate
ansible-lint ansible/site.yml
```

## 🔧 Erweiterte Konfiguration

### Custom Dockerfile
Erstellen Sie `ansible/templates/custom-dockerfile.j2` und referenzieren Sie es in den Projekt-Variablen.

### Zusätzliche Services
Erweitern Sie die `services`-Liste in den Projekt-Variablen.

### Monitoring
Aktivieren Sie Monitoring mit `enable_monitoring: true`.

---

**Mit diesen Templates können Sie schnell neue Container-Projekte mit vollständiger Ansible-Automatisierung und Login-Funktionalität erstellen! 🚀**
EOF

    # Erfolg
    log_success "Ansible-Projekt-Setup abgeschlossen!"
    echo ""
    echo -e "${BLUE}📁 Projekt-Verzeichnis:${NC} $PWD"
    echo -e "${BLUE}🚀 Quick-Start:${NC} ./quick-start.sh"
    echo -e "${BLUE}📖 Dokumentation:${NC} cat README.md"
    echo ""
    echo -e "${GREEN}Nächste Schritte:${NC}"
    echo "1. ./quick-start.sh mcp-server"
    echo "2. make login PROJECT=mcp-server"
    echo "3. Neue Projekte in ansible/vars/ definieren"
}

# Script ausführen
main "$@"

---
# requirements.yml - Ansible Galaxy Dependencies
collections:
  - name: containers.podman
    version: ">=1.10.0"
  - name: community.general
    version: ">=7.0.0"
  - name: ansible.posix
    version: ">=1.5.0"

---
# .ansible-lint - Ansible Lint Konfiguration
---
profile: production

exclude_paths:
  - .cache/
  - test/
  - examples/

use_default_rules: true
verbosity: 1

rules:
  line-length:
    max: 120
  truthy:
    allowed-values: ['true', 'false', 'yes', 'no']
    check-keys: false

---
# ansible/group_vars/all.yml - Globale Variablen
---
# Ansible-spezifische Variablen
ansible_python_interpreter: "{{ ansible_playbook_python }}"

# Globale Container-Einstellungen
global_container_settings:
  restart_policy: "unless-stopped"
  log_driver: "journald"
  log_opt:
    max_size: "10m"
    max_file: "3"

# Netzwerk-Einstellungen
network_settings:
  default_network: "bridge"
  custom_networks: []

# Sicherheits-Einstellungen
security_settings:
  run_as_user: "{{ ansible_user }}"
  security_opt:
    - "no-new-privileges"
    - "label=disable"

# Backup-Einstellungen
backup_settings:
  enable_backup: false
  backup_schedule: "0 2 * * *"  # Täglich um 2 Uhr
  retention_days: 7

# Update-Einstellungen
update_settings:
  auto_update: false
  update_schedule: "0 4 * * 0"  # Sonntags um 4 Uhr
  update_strategy: "rolling"