#!/bin/bash

# =============================================================================
# Ansible Installation Script für Manjaro Linux - ENHANCED VERSION
# =============================================================================
# Dieses Script installiert Ansible und alle benötigten Dependencies
# NEUE FEATURES: Health Dashboard, Remote Management, Playbook Builder, Analytics
# Autor: Claude (Anthropic)
# Version: 2.1 - Enhanced Edition
# =============================================================================

set -e  # Script bei Fehlern beenden

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
BRIGHT_GREEN='\033[1;32m'
BRIGHT_BLUE='\033[1;34m'
BRIGHT_YELLOW='\033[1;33m'
BRIGHT_CYAN='\033[1;36m'
BRIGHT_PURPLE='\033[1;35m'
BRIGHT_RED='\033[1;31m'
NC='\033[0m' # No Color

# Background colors
BG_BLUE='\033[44m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_RED='\033[41m'
BG_PURPLE='\033[45m'
BG_CYAN='\033[46m'

# Logging-Funktionen
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Analytics-Datenbank (CSV-Format)
ANALYTICS_DIR="$HOME/.ansible-analytics"
PERFORMANCE_LOG="$ANALYTICS_DIR/performance.csv"
HEALTH_LOG="$ANALYTICS_DIR/health.csv"
REMOTE_HOSTS_CONFIG="$ANALYTICS_DIR/remote-hosts.conf"

# Analytics initialisieren
init_analytics() {
    mkdir -p "$ANALYTICS_DIR"
    
    # Performance-Log Header
    if [ ! -f "$PERFORMANCE_LOG" ]; then
        echo "timestamp,playbook,duration,tasks,changed,failed,ok,skipped,host,container" > "$PERFORMANCE_LOG"
    fi
    
    # Health-Log Header
    if [ ! -f "$HEALTH_LOG" ]; then
        echo "timestamp,component,status,cpu,memory,disk,details" > "$HEALTH_LOG"
    fi
    
    # Remote-Hosts Konfiguration
    if [ ! -f "$REMOTE_HOSTS_CONFIG" ]; then
        cat > "$REMOTE_HOSTS_CONFIG" << 'EOF'
# Remote Hosts Configuration
# Format: name|host|port|user|key_path|description
# localhost|127.0.0.1|22|developer|~/.ssh/id_rsa|Local Development
EOF
    fi
}

# Performance-Daten loggen
log_performance() {
    local playbook="$1"
    local duration="$2"
    local stats="$3"
    local host="${4:-localhost}"
    local container="${5:-local}"
    
    local timestamp=$(date -Iseconds)
    echo "$timestamp,$playbook,$duration,$stats,$host,$container" >> "$PERFORMANCE_LOG"
}

# Health-Daten loggen
log_health() {
    local component="$1"
    local status="$2"
    local cpu="$3"
    local memory="$4"
    local disk="$5"
    local details="$6"
    
    local timestamp=$(date -Iseconds)
    echo "$timestamp,$component,$status,$cpu,$memory,$disk,$details" >> "$HEALTH_LOG"
}

# Erweiterte UI-Funktionen
print_box() {
    local text="$1"
    local color="${2:-$BLUE}"
    local width=70
    
    echo -e "${color}╔$(printf '═%.0s' $(seq 1 $((width-2))))╗${NC}"
    printf "${color}║${NC}%*s${color}║${NC}\n" $((width-2)) "$text"
    echo -e "${color}╚$(printf '═%.0s' $(seq 1 $((width-2))))╝${NC}"
}

print_dashboard_widget() {
    local title="$1"
    local content="$2"
    local status="$3"
    local color="$4"
    
    # Status-Icon basierend auf Status
    local icon=""
    case $status in
        "healthy") icon="🟢" ;;
        "warning") icon="🟡" ;;
        "critical") icon="🔴" ;;
        "unknown") icon="⚪" ;;
        *) icon="🔵" ;;
    esac
    
    echo -e "${color}┌─ $icon $title ────────────────────────────────────────────────────┐${NC}"
    echo "$content" | while IFS= read -r line; do
        printf "${color}│${NC} %-67s ${color}│${NC}\n" "$line"
    done
    echo -e "${color}└─────────────────────────────────────────────────────────────────────┘${NC}"
}

# 🩺 HEALTH DASHBOARD
show_health_dashboard() {
    clear
    echo -e "${BRIGHT_BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_BLUE}║${NC}                       ${WHITE}🩺 HEALTH DASHBOARD${NC}                           ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    # System-Übersicht
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    
    # System-Status bestimmen
    local system_status="healthy"
    if (( $(echo "$cpu_usage > 80" | bc -l) )) || (( $(echo "$mem_usage > 90" | bc -l) )) || (( $(echo "$disk_usage > 90" | bc -l) )); then
        system_status="critical"
    elif (( $(echo "$cpu_usage > 60" | bc -l) )) || (( $(echo "$mem_usage > 70" | bc -l) )) || (( $(echo "$disk_usage > 80" | bc -l) )); then
        system_status="warning"
    fi
    
    # System-Widget
    print_dashboard_widget "SYSTEM RESOURCES" \
        "CPU: ${cpu_usage}% | Memory: ${mem_usage}% | Disk: ${disk_usage}%
Load: ${load_avg} | Uptime: $(uptime | awk '{print $3,$4}' | sed 's/,//')
Kernel: $(uname -r) | Arch: $(uname -m)" \
        "$system_status" "$CYAN"
    
    echo
    
    # Container-Status
    local container_status="healthy"
    local docker_containers=0
    local podman_containers=0
    local running_containers=0
    
    if command -v docker >/dev/null 2>&1; then
        docker_containers=$(docker ps -a 2>/dev/null | wc -l)
        running_containers=$((running_containers + $(docker ps 2>/dev/null | wc -l) - 1))
    fi
    
    if command -v podman >/dev/null 2>&1; then
        podman_containers=$(podman ps -a 2>/dev/null | wc -l)
        running_containers=$((running_containers + $(podman ps 2>/dev/null | wc -l) - 1))
    fi
    
    if [ $running_containers -eq 0 ] && [ $((docker_containers + podman_containers)) -gt 0 ]; then
        container_status="warning"
    fi
    
    print_dashboard_widget "CONTAINER STATUS" \
        "Docker: $docker_containers containers | Podman: $podman_containers containers
Running: $running_containers | Engines: $(check_container_engines)
Last Activity: $(get_last_container_activity)" \
        "$container_status" "$PURPLE"
    
    echo
    
    # Ansible-Services Status
    local ansible_status="unknown"
    local ansible_info="Not installed"
    
    if command -v ansible >/dev/null 2>&1; then
        local ansible_version=$(ansible --version 2>/dev/null | head -1)
        local python_version=$(python --version 2>/dev/null)
        local config_status="No config"
        
        if [ -f "$HOME/.ansible/ansible.cfg" ]; then
            config_status="Configured"
        fi
        
        ansible_status="healthy"
        ansible_info="Version: $ansible_version
Python: $python_version
Config: $config_status | Projects: $(count_ansible_projects)"
        
        # Ansible-Module prüfen
        if ! python -c "import ansible, jinja2, paramiko, yaml, cryptography" 2>/dev/null; then
            ansible_status="warning"
            ansible_info="$ansible_info
⚠️  Some Python modules missing"
        fi
    else
        ansible_status="critical"
    fi
    
    print_dashboard_widget "ANSIBLE SERVICES" "$ansible_info" "$ansible_status" "$GREEN"
    
    echo
    
    # Network & SSH Status
    local network_status="healthy"
    local ssh_info="SSH Server: $(systemctl is-active ssh 2>/dev/null || echo 'inactive')
SSH Agent: $(pgrep ssh-agent >/dev/null && echo 'running' || echo 'stopped')
Known Hosts: $([ -f ~/.ssh/known_hosts ] && wc -l < ~/.ssh/known_hosts || echo '0') entries
SSH Keys: $(ls ~/.ssh/*.pub 2>/dev/null | wc -l) public keys"
    
    if ! systemctl is-active --quiet ssh 2>/dev/null; then
        network_status="warning"
    fi
    
    print_dashboard_widget "NETWORK & SSH" "$ssh_info" "$network_status" "$YELLOW"
    
    echo
    
    # Performance-Trends (letzte 24h)
    show_performance_trends
    
    # Health-Log aktualisieren
    log_health "system" "$system_status" "$cpu_usage" "$mem_usage" "$disk_usage" "dashboard_check"
    log_health "containers" "$container_status" "0" "0" "0" "docker:$docker_containers,podman:$podman_containers,running:$running_containers"
    log_health "ansible" "$ansible_status" "0" "0" "0" "$ansible_version"
    
    # Interaktive Optionen
    echo
    echo -e "${BRIGHT_CYAN}┌─ 🎮 DASHBOARD AKTIONEN ───────────────────────────────────────────┐${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}1)${NC} 🔄 Dashboard aktualisieren                                  ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}2)${NC} 📊 Detaillierte Systeminfo                                 ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}3)${NC} 🩹 Automatische Problembehebung                           ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}4)${NC} 📈 Performance-Historie anzeigen                           ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}5)${NC} 🔔 Überwachung starten (Live-Updates)                     ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}6)${NC} 🔙 Zurück zum Hauptmenü                                   ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    read -p "$(echo -e "${WHITE}Wähle eine Aktion: ${NC}")" dashboard_action
    
    case $dashboard_action in
        1) show_health_dashboard ;;
        2) show_detailed_system_info ;;
        3) auto_fix_problems ;;
        4) show_performance_history ;;
        5) start_live_monitoring ;;
        6) return 0 ;;
        *) 
            echo -e "${RED}❌ Ungültige Auswahl${NC}"
            sleep 2
            show_health_dashboard
            ;;
    esac
}

# Helper-Funktionen für Health Dashboard
check_container_engines() {
    local engines=""
    if command -v docker >/dev/null 2>&1; then
        engines="Docker"
    fi
    if command -v podman >/dev/null 2>&1; then
        engines="${engines:+$engines, }Podman"
    fi
    echo "${engines:-None}"
}

get_last_container_activity() {
    local last_activity="Never"
    
    # Docker letzte Aktivität
    if command -v docker >/dev/null 2>&1; then
        local docker_activity=$(docker ps -a --format "{{.CreatedAt}}" 2>/dev/null | head -1)
        if [ -n "$docker_activity" ]; then
            last_activity="$docker_activity"
        fi
    fi
    
    # Podman letzte Aktivität
    if command -v podman >/dev/null 2>&1; then
        local podman_activity=$(podman ps -a --format "{{.CreatedAt}}" 2>/dev/null | head -1)
        if [ -n "$podman_activity" ]; then
            last_activity="$podman_activity"
        fi
    fi
    
    echo "$last_activity"
}

count_ansible_projects() {
    local count=0
    if [ -d "$HOME/ansible-projekte" ]; then
        count=$(find "$HOME/ansible-projekte" -maxdepth 1 -type d | wc -l)
        count=$((count - 1))  # Exclude parent directory
    fi
    echo "$count"
}

show_performance_trends() {
    echo -e "${BRIGHT_GREEN}┌─ 📈 PERFORMANCE TRENDS (24h) ──────────────────────────────────────┐${NC}"
    
    if [ -f "$PERFORMANCE_LOG" ]; then
        local total_runs=$(tail -n +2 "$PERFORMANCE_LOG" | wc -l)
        local avg_duration=0
        local failed_runs=0
        
        if [ $total_runs -gt 0 ]; then
            # Durchschnittliche Ausführungszeit berechnen
            avg_duration=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$3; count++} END {if(count>0) print sum/count; else print 0}')
            failed_runs=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '$6>0' | wc -l)
        fi
        
        printf "${BRIGHT_GREEN}│${NC} Playbook Runs: %-10s | Avg Duration: %-15s      ${BRIGHT_GREEN}│${NC}\n" "$total_runs" "${avg_duration}s"
        printf "${BRIGHT_GREEN}│${NC} Failed Runs: %-12s | Success Rate: %-15s     ${BRIGHT_GREEN}│${NC}\n" "$failed_runs" "$(( (total_runs - failed_runs) * 100 / (total_runs == 0 ? 1 : total_runs) ))%"
    else
        printf "${BRIGHT_GREEN}│${NC} %-67s ${BRIGHT_GREEN}│${NC}\n" "No performance data available yet"
    fi
    
    echo -e "${BRIGHT_GREEN}└─────────────────────────────────────────────────────────────────────┘${NC}"
}

show_detailed_system_info() {
    clear
    echo -e "${BRIGHT_BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_BLUE}║${NC}                    ${WHITE}🔍 DETAILLIERTE SYSTEMINFO${NC}                       ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    echo -e "${CYAN}=== SYSTEM ===${NC}"
    echo "Hostname: $(hostname)"
    echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
    echo "Kernel: $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "Uptime: $(uptime -p)"
    
    echo
    echo -e "${CYAN}=== CPU ===${NC}"
    echo "Model: $(lscpu | grep 'Model name' | awk -F: '{print $2}' | sed 's/^[ \t]*//')"
    echo "Cores: $(nproc)"
    echo "Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
    
    echo
    echo -e "${CYAN}=== MEMORY ===${NC}"
    free -h
    
    echo
    echo -e "${CYAN}=== DISK USAGE ===${NC}"
    df -h / /tmp /home 2>/dev/null | head -4
    
    echo
    echo -e "${CYAN}=== NETWORK ===${NC}"
    ip addr show | grep -E "inet |^[0-9]+" | head -10
    
    echo
    echo -e "${CYAN}=== RUNNING SERVICES ===${NC}"
    systemctl --type=service --state=running | head -10
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
}

auto_fix_problems() {
    clear
    echo -e "${BRIGHT_YELLOW}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_YELLOW}║${NC}                   ${WHITE}🩹 AUTOMATISCHE PROBLEMBEHEBUNG${NC}                  ${BRIGHT_YELLOW}║${NC}"
    echo -e "${BRIGHT_YELLOW}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    log_info "Prüfe häufige Probleme und versuche automatische Behebung..."
    
    local fixes_applied=0
    
    # Docker-Berechtigung prüfen
    if command -v docker >/dev/null 2>&1 && ! docker ps >/dev/null 2>&1; then
        echo
        log_warning "Docker-Berechtigungsproblem erkannt"
        read -p "Docker-Berechtigung reparieren? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            sudo usermod -aG docker "$USER"
            log_success "Benutzer zur docker-Gruppe hinzugefügt"
            log_info "Bitte Terminal neu starten oder 'newgrp docker' ausführen"
            fixes_applied=$((fixes_applied + 1))
        fi
    fi
    
    # SSH-Agent prüfen
    if ! pgrep ssh-agent >/dev/null; then
        echo
        log_warning "SSH-Agent läuft nicht"
        read -p "SSH-Agent starten? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            eval "$(ssh-agent -s)"
            if [ -f ~/.ssh/id_rsa ]; then
                ssh-add ~/.ssh/id_rsa
            fi
            log_success "SSH-Agent gestartet"
            fixes_applied=$((fixes_applied + 1))
        fi
    fi
    
    # Ansible-Konfiguration prüfen
    if command -v ansible >/dev/null 2>&1 && [ ! -f ~/.ansible/ansible.cfg ]; then
        echo
        log_warning "Ansible-Konfiguration fehlt"
        read -p "Standard-Konfiguration erstellen? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            setup_ansible_config
            log_success "Ansible-Konfiguration erstellt"
            fixes_applied=$((fixes_applied + 1))
        fi
    fi
    
    # Python-Module prüfen
    if command -v python >/dev/null 2>&1; then
        missing_modules=()
        for module in jinja2 paramiko yaml cryptography; do
            if ! python -c "import $module" 2>/dev/null; then
                missing_modules+=("$module")
            fi
        done
        
        if [ ${#missing_modules[@]} -gt 0 ]; then
            echo
            log_warning "Fehlende Python-Module: ${missing_modules[*]}"
            read -p "Module installieren? (Y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                pip install --user "${missing_modules[@]}"
                log_success "Python-Module installiert"
                fixes_applied=$((fixes_applied + 1))
            fi
        fi
    fi
    
    # Gestoppte Container prüfen
    local stopped_containers=()
    if command -v docker >/dev/null 2>&1; then
        stopped_containers+=($(docker ps -a --filter "status=exited" --filter "name=-docker" --format "{{.Names}}" 2>/dev/null))
    fi
    
    if [ ${#stopped_containers[@]} -gt 0 ]; then
        echo
        log_warning "Gestoppte Container gefunden: ${stopped_containers[*]}"
        read -p "Container starten? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            for container in "${stopped_containers[@]}"; do
                docker start "$container" && log_success "Container '$container' gestartet"
            done
            fixes_applied=$((fixes_applied + 1))
        fi
    fi
    
    echo
    if [ $fixes_applied -gt 0 ]; then
        log_success "$fixes_applied Problem(e) behoben!"
        echo
        log_info "Empfehlung: Dashboard aktualisieren für aktuellen Status"
    else
        log_info "Keine automatisch behebbaren Probleme gefunden"
        log_success "System scheint in gutem Zustand zu sein!"
    fi
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
}

start_live_monitoring() {
    clear
    echo -e "${BRIGHT_PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_PURPLE}║${NC}                     ${WHITE}🔔 LIVE-ÜBERWACHUNG${NC}                            ${BRIGHT_PURPLE}║${NC}"
    echo -e "${BRIGHT_PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    log_info "Starte Live-Überwachung (Ctrl+C zum Beenden)..."
    echo
    
    # Live-Updates alle 5 Sekunden
    while true; do
        clear
        echo -e "${PURPLE}🔔 LIVE MONITORING - $(date)${NC}"
        echo
        
        # System-Ressourcen
        local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        local mem=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
        local disk=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
        
        printf "CPU: %6s%% " "$cpu"
        show_bar "$cpu" 100 20
        printf "MEM: %6s%% " "$mem"
        show_bar "$mem" 100 20
        printf "DISK: %5s%% " "$disk"
        show_bar "$disk" 100 20
        
        echo
        echo
        
        # Container-Status
        echo -e "${BLUE}=== CONTAINER STATUS ===${NC}"
        if command -v docker >/dev/null 2>&1; then
            local running_docker=$(docker ps --format "{{.Names}}" 2>/dev/null | wc -l)
            echo "Docker: $running_docker running"
        fi
        
        if command -v podman >/dev/null 2>&1; then
            local running_podman=$(podman ps --format "{{.Names}}" 2>/dev/null | wc -l)
            echo "Podman: $running_podman running"
        fi
        
        echo
        echo -e "${GRAY}Nächstes Update in 5 Sekunden... (Ctrl+C zum Beenden)${NC}"
        
        # Log health data
        log_health "live_monitor" "running" "$cpu" "$mem" "$disk" "live_monitoring"
        
        sleep 5
    done
}

show_bar() {
    local value=$1
    local max=$2
    local width=$3
    local filled=$(( value * width / max ))
    
    printf "["
    for ((i=1; i<=width; i++)); do
        if [ $i -le $filled ]; then
            printf "█"
        else
            printf "░"
        fi
    done
    printf "] "
}

# 🌐 REMOTE CONTAINER MANAGEMENT
show_remote_management() {
    clear
    echo -e "${BRIGHT_CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_CYAN}║${NC}                   ${WHITE}🌐 REMOTE CONTAINER MANAGEMENT${NC}                  ${BRIGHT_CYAN}║${NC}"
    echo -e "${BRIGHT_CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Remote-Hosts laden
    load_remote_hosts
    
    echo
    echo -e "${CYAN}┌─ 🖥️  VERFÜGBARE REMOTE HOSTS ─────────────────────────────────────────┐${NC}"
    
    if [ ${#REMOTE_HOSTS[@]} -eq 0 ]; then
        echo -e "${CYAN}│${NC} Keine Remote-Hosts konfiguriert.                               ${CYAN}│${NC}"
        echo -e "${CYAN}│${NC} Verwende Option 1 um einen Host hinzuzufügen.                 ${CYAN}│${NC}"
    else
        echo -e "${CYAN}│${NC} ${WHITE}Name${NC}          ${WHITE}Host${NC}                ${WHITE}Status${NC}            ${WHITE}Containers${NC}   ${CYAN}│${NC}"
        echo -e "${CYAN}├─────────────────────────────────────────────────────────────────────┤${NC}"
        
        for host_info in "${REMOTE_HOSTS[@]}"; do
            local name=$(echo "$host_info" | cut -d'|' -f1)
            local host=$(echo "$host_info" | cut -d'|' -f2)
            local port=$(echo "$host_info" | cut -d'|' -f3)
            local user=$(echo "$host_info" | cut -d'|' -f4)
            
            # Host-Status prüfen
            local status="🔴 Offline"
            local containers="N/A"
            
            if ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no -p "$port" "$user@$host" "echo 'connected'" 2>/dev/null | grep -q "connected"; then
                status="🟢 Online"
                containers=$(ssh -p "$port" "$user@$host" "docker ps 2>/dev/null | wc -l" 2>/dev/null || echo "0")
                containers=$((containers - 1))  # Subtract header line
                containers="${containers} containers"
            fi
            
            printf "${CYAN}│${NC} %-12s %-19s %-16s %-12s ${CYAN}│${NC}\n" "$name" "$host:$port" "$status" "$containers"
        done
    fi
    
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    echo -e "${BRIGHT_YELLOW}┌─ 🎮 REMOTE AKTIONEN ───────────────────────────────────────────────┐${NC}"
    echo -e "${BRIGHT_YELLOW}│${NC} ${WHITE}1)${NC} 🆕 Remote-Host hinzufügen                                    ${BRIGHT_YELLOW}│${NC}"
    echo -e "${BRIGHT_YELLOW}│${NC} ${WHITE}2)${NC} 🔗 Mit Remote-Host verbinden                                 ${BRIGHT_YELLOW}│${NC}"
    echo -e "${BRIGHT_YELLOW}│${NC} ${WHITE}3)${NC} 📊 Remote-Host Status prüfen                                ${BRIGHT_YELLOW}│${NC}"
    echo -e "${BRIGHT_YELLOW}│${NC} ${WHITE}4)${NC} 🐳 Remote-Container verwalten                               ${BRIGHT_YELLOW}│${NC}"
    echo -e "${BRIGHT_YELLOW}│${NC} ${WHITE}5)${NC} 🚀 Ansible auf Remote-Host installieren                     ${BRIGHT_YELLOW}│${NC}"
    echo -e "${BRIGHT_YELLOW}│${NC} ${WHITE}6)${NC} ⚙️  Remote-Host bearbeiten/löschen                          ${BRIGHT_YELLOW}│${NC}"
    echo -e "${BRIGHT_YELLOW}│${NC} ${WHITE}7)${NC} 📋 Remote-Hosts exportieren/importieren                     ${BRIGHT_YELLOW}│${NC}"
    echo -e "${BRIGHT_YELLOW}│${NC} ${WHITE}8)${NC} 🔙 Zurück zum Hauptmenü                                     ${BRIGHT_YELLOW}│${NC}"
    echo -e "${BRIGHT_YELLOW}└─────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    read -p "$(echo -e "${WHITE}Wähle eine Aktion: ${NC}")" remote_action
    
    case $remote_action in
        1) add_remote_host ;;
        2) connect_to_remote_host ;;
        3) check_remote_host_status ;;
        4) manage_remote_containers ;;
        5) install_ansible_remote ;;
        6) edit_remote_hosts ;;
        7) export_import_hosts ;;
        8) return 0 ;;
        *) 
            echo -e "${RED}❌ Ungültige Auswahl${NC}"
            sleep 2
            show_remote_management
            ;;
    esac
}

declare -a REMOTE_HOSTS

load_remote_hosts() {
    REMOTE_HOSTS=()
    if [ -f "$REMOTE_HOSTS_CONFIG" ]; then
        while IFS= read -r line; do
            # Skip comments and empty lines
            if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
                continue
            fi
            REMOTE_HOSTS+=("$line")
        done < "$REMOTE_HOSTS_CONFIG"
    fi
}

add_remote_host() {
    echo
    echo -e "${BLUE}=== 🆕 REMOTE HOST HINZUFÜGEN ===${NC}"
    echo
    
    read -p "Host-Name (z.B. 'production'): " host_name
    read -p "Hostname/IP (z.B. '192.168.1.100'): " hostname
    read -p "SSH-Port [22]: " ssh_port
    ssh_port=${ssh_port:-22}
    read -p "Benutzername [$(whoami)]: " username
    username=${username:-$(whoami)}
    read -p "SSH-Key Pfad [~/.ssh/id_rsa]: " key_path
    key_path=${key_path:-~/.ssh/id_rsa}
    read -p "Beschreibung: " description
    
    # Verbindung testen
    echo
    log_info "Teste Verbindung zu $username@$hostname:$ssh_port..."
    
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no -p "$ssh_port" "$username@$hostname" "echo 'Verbindung erfolgreich'" 2>/dev/null | grep -q "erfolgreich"; then
        log_success "Verbindung erfolgreich!"
        
        # Host zur Konfiguration hinzufügen
        echo "$host_name|$hostname|$ssh_port|$username|$key_path|$description" >> "$REMOTE_HOSTS_CONFIG"
        log_success "Remote-Host '$host_name' hinzugefügt"
        
        # Optional: SSH-Key kopieren
        read -p "SSH-Key zum Remote-Host kopieren? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]] && [ -f "${key_path}.pub" ]; then
            ssh-copy-id -i "$key_path" -p "$ssh_port" "$username@$hostname"
            log_success "SSH-Key kopiert"
        fi
        
    else
        log_error "Verbindung fehlgeschlagen!"
        echo "Prüfe:"
        echo "- Hostname/IP korrekt?"
        echo "- SSH-Service läuft auf Ziel-Host?"
        echo "- Port $ssh_port erreichbar?"
        echo "- Benutzer '$username' existiert?"
    fi
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
    show_remote_management
}

connect_to_remote_host() {
    if [ ${#REMOTE_HOSTS[@]} -eq 0 ]; then
        log_error "Keine Remote-Hosts konfiguriert"
        sleep 2
        show_remote_management
        return
    fi
    
    echo
    echo -e "${BLUE}=== 🔗 REMOTE-HOST AUSWÄHLEN ===${NC}"
    echo
    
    for i in "${!REMOTE_HOSTS[@]}"; do
        local host_info="${REMOTE_HOSTS[$i]}"
        local name=$(echo "$host_info" | cut -d'|' -f1)
        local host=$(echo "$host_info" | cut -d'|' -f2)
        local description=$(echo "$host_info" | cut -d'|' -f6)
        echo "$((i+1))) $name ($host) - $description"
    done
    echo
    
    read -p "Host auswählen [1-${#REMOTE_HOSTS[@]}]: " host_choice
    
    if [[ "$host_choice" =~ ^[0-9]+$ ]] && [ "$host_choice" -ge 1 ] && [ "$host_choice" -le ${#REMOTE_HOSTS[@]} ]; then
        local selected_host="${REMOTE_HOSTS[$((host_choice-1))]}"
        local host=$(echo "$selected_host" | cut -d'|' -f2)
        local port=$(echo "$selected_host" | cut -d'|' -f3)
        local user=$(echo "$selected_host" | cut -d'|' -f4)
        
        log_info "Verbinde mit $user@$host:$port..."
        ssh -p "$port" "$user@$host"
    else
        log_error "Ungültige Auswahl"
        sleep 2
    fi
    
    show_remote_management
}

manage_remote_containers() {
    if [ ${#REMOTE_HOSTS[@]} -eq 0 ]; then
        log_error "Keine Remote-Hosts konfiguriert"
        sleep 2
        show_remote_management
        return
    fi
    
    echo
    echo -e "${BLUE}=== 🐳 REMOTE-CONTAINER MANAGEMENT ===${NC}"
    echo
    
    for i in "${!REMOTE_HOSTS[@]}"; do
        local host_info="${REMOTE_HOSTS[$i]}"
        local name=$(echo "$host_info" | cut -d'|' -f1)
        local host=$(echo "$host_info" | cut -d'|' -f2)
        echo "$((i+1))) $name ($host)"
    done
    echo
    
    read -p "Host auswählen [1-${#REMOTE_HOSTS[@]}]: " host_choice
    
    if [[ "$host_choice" =~ ^[0-9]+$ ]] && [ "$host_choice" -ge 1 ] && [ "$host_choice" -le ${#REMOTE_HOSTS[@]} ]; then
        local selected_host="${REMOTE_HOSTS[$((host_choice-1))]}"
        local host=$(echo "$selected_host" | cut -d'|' -f2)
        local port=$(echo "$selected_host" | cut -d'|' -f3)
        local user=$(echo "$selected_host" | cut -d'|' -f4)
        local name=$(echo "$selected_host" | cut -d'|' -f1)
        
        echo
        log_info "Lade Container-Info von $name..."
        
        # Remote-Container auflisten
        local containers=$(ssh -p "$port" "$user@$host" "docker ps -a --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'" 2>/dev/null)
        
        if [ $? -eq 0 ] && [ -n "$containers" ]; then
            echo
            echo -e "${GREEN}Container auf $name:${NC}"
            echo "$containers"
            
            echo
            echo "Aktionen:"
            echo "1) Container starten/stoppen"
            echo "2) Container-Shell öffnen"
            echo "3) Container-Logs anzeigen"
            echo "4) Neuen Container erstellen"
            
            read -p "Aktion wählen [1-4]: " container_action
            
            case $container_action in
                1)
                    read -p "Container-Name: " container_name
                    read -p "Starten (s) oder Stoppen (t)? [s/t]: " action
                    
                    if [ "$action" = "s" ]; then
                        ssh -p "$port" "$user@$host" "docker start $container_name"
                    else
                        ssh -p "$port" "$user@$host" "docker stop $container_name"
                    fi
                    ;;
                2)
                    read -p "Container-Name: " container_name
                    ssh -t -p "$port" "$user@$host" "docker exec -it $container_name /bin/bash"
                    ;;
                3)
                    read -p "Container-Name: " container_name
                    ssh -p "$port" "$user@$host" "docker logs $container_name"
                    ;;
                4)
                    echo "Remote-Container-Erstellung wird in einem kommenden Update verfügbar sein"
                    ;;
            esac
        else
            log_warning "Keine Container gefunden oder Docker nicht verfügbar auf $name"
        fi
    else
        log_error "Ungültige Auswahl"
    fi
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
    show_remote_management
}

# 🎮 INTERACTIVE PLAYBOOK BUILDER
show_playbook_builder() {
    clear
    echo -e "${BRIGHT_GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_GREEN}║${NC}                  ${WHITE}🎮 INTERACTIVE PLAYBOOK BUILDER${NC}                  ${BRIGHT_GREEN}║${NC}"
    echo -e "${BRIGHT_GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    echo -e "${GREEN}Willkommen zum interaktiven Playbook Builder!${NC}"
    echo "Hier kannst du Schritt für Schritt Ansible-Playbooks erstellen."
    echo
    
    echo -e "${CYAN}┌─ 📝 PLAYBOOK OPTIONEN ────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}1)${NC} 🆕 Neues Playbook erstellen                                     ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}2)${NC} 📖 Vorhandenes Playbook bearbeiten                             ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}3)${NC} 📋 Playbook-Templates anzeigen                                 ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}4)${NC} 🧪 Playbook testen (Dry-Run)                                   ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}5)${NC} ✅ Playbook validieren (Lint)                                  ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}6)${NC} 🚀 Playbook ausführen                                          ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}7)${NC} 📚 Playbook-Galerie (Beispiele)                               ${CYAN}│${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}8)${NC} 🔙 Zurück zum Hauptmenü                                        ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    read -p "$(echo -e "${WHITE}Wähle eine Option: ${NC}")" builder_action
    
    case $builder_action in
        1) create_new_playbook ;;
        2) edit_existing_playbook ;;
        3) show_playbook_templates ;;
        4) test_playbook_dry_run ;;
        5) validate_playbook ;;
        6) execute_playbook ;;
        7) show_playbook_gallery ;;
        8) return 0 ;;
        *) 
            echo -e "${RED}❌ Ungültige Auswahl${NC}"
            sleep 2
            show_playbook_builder
            ;;
    esac
}

create_new_playbook() {
    echo
    echo -e "${BRIGHT_GREEN}=== 🆕 NEUES PLAYBOOK ERSTELLEN ===${NC}"
    echo
    
    # Grundlegende Informationen sammeln
    read -p "Playbook-Name (ohne .yml): " playbook_name
    read -p "Beschreibung: " playbook_description
    read -p "Ziel-Hosts (z.B. 'all', 'localhost'): " target_hosts
    target_hosts=${target_hosts:-localhost}
    
    # Erweiterte Optionen
    echo
    echo "Erweiterte Optionen:"
    read -p "Benutzer für Remote-Ausführung [ansible]: " remote_user
    remote_user=${remote_user:-ansible}
    
    read -p "Sudo verwenden? (y/N): " -n 1 -r use_sudo
    echo
    
    read -p "Facts sammeln? (Y/n): " -n 1 -r gather_facts
    echo
    
    # Playbook-Struktur erstellen
    local playbook_dir="$HOME/ansible-projekte/$playbook_name"
    mkdir -p "$playbook_dir"/{playbooks,inventory,vars,templates,files}
    
    # Inventory erstellen
    cat > "$playbook_dir/inventory/hosts.yml" << EOF
all:
  children:
    target_group:
      hosts:
        $target_hosts:
          ansible_connection: local
      vars:
        ansible_user: $remote_user
EOF
    
    # Playbook-Grundgerüst
    cat > "$playbook_dir/playbooks/${playbook_name}.yml" << EOF
---
# $playbook_description
# Erstellt mit Ansible Interactive Builder
# Datum: $(date)

- name: $playbook_description
  hosts: $target_hosts
  remote_user: $remote_user
  gather_facts: $([[ $gather_facts =~ ^[Nn]$ ]] && echo "false" || echo "true")
  become: $([[ $use_sudo =~ ^[Yy]$ ]] && echo "true" || echo "false")
  
  vars:
    # Definiere hier deine Variablen
    project_name: "$playbook_name"
    created_by: "$(whoami)"
    creation_date: "$(date)"
  
  tasks:
    - name: Playbook-Start melden
      debug:
        msg: |
          🚀 Starte Playbook: $playbook_description
          Host: {{ inventory_hostname }}
          Benutzer: {{ ansible_user_id }}
          Datum: {{ ansible_date_time.iso8601 }}
EOF
    
    echo
    log_success "Playbook-Grundgerüst erstellt: $playbook_dir"
    
    # Interaktive Task-Erstellung
    while true; do
        echo
        echo -e "${YELLOW}=== TASKS HINZUFÜGEN ===${NC}"
        echo "1) Package installieren"
        echo "2) Datei/Verzeichnis erstellen"
        echo "3) Service starten/stoppen"
        echo "4) Kommando ausführen"
        echo "5) Template kopieren"
        echo "6) Custom Task (manuell)"
        echo "7) Playbook beenden"
        
        read -p "Task-Typ wählen [1-7]: " task_type
        
        case $task_type in
            1) add_package_task "$playbook_dir/playbooks/${playbook_name}.yml" ;;
            2) add_file_task "$playbook_dir/playbooks/${playbook_name}.yml" ;;
            3) add_service_task "$playbook_dir/playbooks/${playbook_name}.yml" ;;
            4) add_command_task "$playbook_dir/playbooks/${playbook_name}.yml" ;;
            5) add_template_task "$playbook_dir/playbooks/${playbook_name}.yml" "$playbook_dir" ;;
            6) add_custom_task "$playbook_dir/playbooks/${playbook_name}.yml" ;;
            7) break ;;
            *) echo "Ungültige Auswahl" ;;
        esac
    done
    
    # Abschluss
    cat >> "$playbook_dir/playbooks/${playbook_name}.yml" << EOF
    
    - name: Playbook erfolgreich abgeschlossen
      debug:
        msg: "✅ Playbook '$playbook_description' erfolgreich ausgeführt!"
EOF
    
    echo
    log_success "Playbook '$playbook_name' erstellt!"
    echo
    echo "Verfügbare Dateien:"
    echo "• Playbook: $playbook_dir/playbooks/${playbook_name}.yml"
    echo "• Inventory: $playbook_dir/inventory/hosts.yml"
    echo "• Verzeichnisse: vars/, templates/, files/"
    echo
    echo "Nächste Schritte:"
    echo "1) Playbook testen: ansible-playbook --check playbooks/${playbook_name}.yml"
    echo "2) Playbook ausführen: ansible-playbook playbooks/${playbook_name}.yml"
    
    read -p "$(echo -e "${CYAN}Playbook jetzt testen? (Y/n): ${NC}")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        cd "$playbook_dir"
        ansible-playbook --check "playbooks/${playbook_name}.yml" -i inventory/hosts.yml
    fi
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
    show_playbook_builder
}

add_package_task() {
    local playbook_file="$1"
    
    echo
    read -p "Package-Name: " package_name
    read -p "Package-Manager (pacman/apt/yum/dnf) [pacman]: " package_manager
    package_manager=${package_manager:-pacman}
    
    read -p "Aktion (present/absent/latest) [present]: " package_state
    package_state=${package_state:-present}
    
    cat >> "$playbook_file" << EOF
    
    - name: Package '$package_name' installieren
      package:
        name: $package_name
        state: $package_state
      when: ansible_pkg_mgr == "$package_manager"
      
    # Fallback für andere Package-Manager
    - name: Package '$package_name' mit spezifischem Manager
      $package_manager:
        name: $package_name
        state: $package_state
      when: ansible_pkg_mgr != "$package_manager"
EOF

    log_success "Package-Task hinzugefügt: $package_name"
}

add_file_task() {
    local playbook_file="$1"
    
    echo
    read -p "Datei/Verzeichnis-Pfad: " file_path
    echo "Typ wählen:"
    echo "1) Datei erstellen"
    echo "2) Verzeichnis erstellen"  
    echo "3) Datei kopieren"
    echo "4) Datei mit Inhalt erstellen"
    
    read -p "Typ [1-4]: " file_type
    
    case $file_type in
        1)
            cat >> "$playbook_file" << EOF
    
    - name: Datei erstellen: $file_path
      file:
        path: $file_path
        state: touch
        mode: '0644'
EOF
            ;;
        2)
            read -p "Verzeichnis-Modus [0755]: " dir_mode
            dir_mode=${dir_mode:-0755}
            cat >> "$playbook_file" << EOF
    
    - name: Verzeichnis erstellen: $file_path
      file:
        path: $file_path
        state: directory
        mode: '$dir_mode'
EOF
            ;;
        3)
            read -p "Quell-Datei (relativ zu files/): " src_file
            cat >> "$playbook_file" << EOF
    
    - name: Datei kopieren: $src_file -> $file_path
      copy:
        src: $src_file
        dest: $file_path
        mode: '0644'
        backup: true
EOF
            ;;
        4)
            read -p "Datei-Inhalt: " file_content
            cat >> "$playbook_file" << EOF
    
    - name: Datei mit Inhalt erstellen: $file_path
      copy:
        content: |
          $file_content
        dest: $file_path
        mode: '0644'
EOF
            ;;
    esac
    
    log_success "File-Task hinzugefügt: $file_path"
}

add_service_task() {
    local playbook_file="$1"
    
    echo
    read -p "Service-Name: " service_name
    echo "Aktion wählen:"
    echo "1) Service starten und aktivieren"
    echo "2) Service stoppen und deaktivieren"
    echo "3) Service neustarten"
    echo "4) Service-Status prüfen"
    
    read -p "Aktion [1-4]: " service_action
    
    case $service_action in
        1)
            cat >> "$playbook_file" << EOF
    
    - name: Service starten und aktivieren: $service_name
      systemd:
        name: $service_name
        state: started
        enabled: true
        daemon_reload: true
EOF
            ;;
        2)
            cat >> "$playbook_file" << EOF
    
    - name: Service stoppen und deaktivieren: $service_name
      systemd:
        name: $service_name
        state: stopped
        enabled: false
EOF
            ;;
        3)
            cat >> "$playbook_file" << EOF
    
    - name: Service neustarten: $service_name
      systemd:
        name: $service_name
        state: restarted
        daemon_reload: true
EOF
            ;;
        4)
            cat >> "$playbook_file" << EOF
    
    - name: Service-Status prüfen: $service_name
      service_facts:
      
    - name: Service-Info anzeigen: $service_name
      debug:
        msg: |
          Service: $service_name
          Status: {{ ansible_facts.services['$service_name.service'].state | default('not found') }}
          Enabled: {{ ansible_facts.services['$service_name.service'].status | default('unknown') }}
EOF
            ;;
    esac
    
    log_success "Service-Task hinzugefügt: $service_name"
}

add_command_task() {
    local playbook_file="$1"
    
    echo
    read -p "Kommando: " command
    read -p "Arbeitsverzeichnis [/tmp]: " working_dir
    working_dir=${working_dir:-/tmp}
    
    read -p "Nur ausführen wenn Datei existiert? (Pfad oder leer): " creates_file
    
    cat >> "$playbook_file" << EOF
    
    - name: Kommando ausführen: $command
      command: $command
      args:
        chdir: $working_dir
EOF

    if [ -n "$creates_file" ]; then
        cat >> "$playbook_file" << EOF
        creates: $creates_file
EOF
    fi

    cat >> "$playbook_file" << EOF
      register: command_result
      
    - name: Kommando-Ergebnis anzeigen
      debug:
        var: command_result.stdout_lines
      when: command_result.stdout_lines is defined
EOF
    
    log_success "Command-Task hinzugefügt: $command"
}

show_playbook_templates() {
    echo
    echo -e "${BRIGHT_BLUE}=== 📋 PLAYBOOK TEMPLATES ===${NC}"
    echo
    
    echo -e "${CYAN}Verfügbare Templates:${NC}"
    echo "1) 🌐 Webserver-Setup (Nginx + SSL)"
    echo "2) 🐳 Docker-Installation und -Konfiguration"
    echo "3) 🔐 SSH-Hardening und Sicherheit"
    echo "4) 📦 Development-Environment Setup"
    echo "5) 🔄 System-Update und Maintenance"
    echo "6) 📊 Monitoring-Setup (Prometheus + Grafana)"
    echo "7) 🗄️  Database-Setup (PostgreSQL/MySQL)"
    echo "8) 🔙 Zurück"
    
    echo
    read -p "Template auswählen [1-8]: " template_choice
    
    case $template_choice in
        1) create_webserver_template ;;
        2) create_docker_template ;;
        3) create_ssh_hardening_template ;;
        4) create_development_template ;;
        5) create_maintenance_template ;;
        6) create_monitoring_template ;;
        7) create_database_template ;;
        8) show_playbook_builder ;;
        *) 
            echo -e "${RED}❌ Ungültige Auswahl${NC}"
            sleep 2
            show_playbook_templates
            ;;
    esac
}

create_webserver_template() {
    local template_dir="$HOME/ansible-projekte/webserver-nginx"
    mkdir -p "$template_dir"/{playbooks,inventory,templates,files,vars}
    
    # Inventory
    cat > "$template_dir/inventory/hosts.yml" << 'EOF'
all:
  children:
    webservers:
      hosts:
        localhost:
          ansible_connection: local
        # Weitere Webserver hier hinzufügen
      vars:
        ansible_user: ansible
        nginx_port: 80
        ssl_port: 443
        domain_name: example.com
EOF

    # Variables
    cat > "$template_dir/vars/main.yml" << 'EOF'
---
# Webserver-Konfiguration
nginx_version: latest
ssl_enabled: true
firewall_enabled: true

# SSL-Konfiguration
ssl_certificate_path: "/etc/ssl/certs/{{ domain_name }}.crt"
ssl_private_key_path: "/etc/ssl/private/{{ domain_name }}.key"

# Website-Konfiguration
website_root: "/var/www/{{ domain_name }}"
index_files:
  - index.html
  - index.php

# Nginx-Module
nginx_modules:
  - ssl
  - gzip
  - headers
EOF

    # Nginx-Konfiguration Template
    cat > "$template_dir/templates/nginx-site.conf.j2" << 'EOF'
server {
    listen {{ nginx_port }};
    server_name {{ domain_name }} www.{{ domain_name }};
    
    {% if ssl_enabled %}
    # Redirect HTTP to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen {{ ssl_port }} ssl http2;
    server_name {{ domain_name }} www.{{ domain_name }};
    
    # SSL-Konfiguration
    ssl_certificate {{ ssl_certificate_path }};
    ssl_certificate_key {{ ssl_private_key_path }};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512;
    ssl_prefer_server_ciphers off;
    
    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    {% endif %}
    
    # Document Root
    root {{ website_root }};
    index {{ index_files | join(' ') }};
    
    # Gzip Compression
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
    
    location / {
        try_files $uri $uri/ =404;
    }
    
    # Logs
    access_log /var/log/nginx/{{ domain_name }}.access.log;
    error_log /var/log/nginx/{{ domain_name }}.error.log;
}
EOF

    # Standard-Website
    cat > "$template_dir/files/index.html" << 'EOF'
<!DOCTYPE html>
<html lang="de">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Willkommen - Nginx Server</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f4f4f4; }
        .container { background: white; padding: 40px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; }
        .status { background: #27ae60; color: white; padding: 10px; border-radius: 5px; display: inline-block; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Nginx Server erfolgreich konfiguriert!</h1>
        <div class="status">✅ Server läuft</div>
        <p>Dein Webserver wurde erfolgreich mit Ansible eingerichtet.</p>
        <ul>
            <li>Nginx-Version: {{ nginx_version }}</li>
            <li>SSL aktiviert: {{ ssl_enabled }}</li>
            <li>Domain: {{ domain_name }}</li>
        </ul>
    </div>
</body>
</html>
EOF

    # Hauptplaybook
    cat > "$template_dir/playbooks/webserver-setup.yml" << 'EOF'
---
- name: Nginx Webserver Setup mit SSL
  hosts: webservers
  become: true
  vars_files:
    - ../vars/main.yml
    
  tasks:
    - name: System-Pakete aktualisieren
      package:
        update_cache: true
        
    - name: Nginx installieren
      package:
        name: nginx
        state: present
        
    - name: UFW Firewall installieren (Ubuntu/Debian)
      package:
        name: ufw
        state: present
      when: ansible_os_family == "Debian" and firewall_enabled
      
    - name: Website-Verzeichnis erstellen
      file:
        path: "{{ website_root }}"
        state: directory
        owner: www-data
        group: www-data
        mode: '0755'
        
    - name: Standard-Website kopieren
      copy:
        src: ../files/index.html
        dest: "{{ website_root }}/index.html"
        owner: www-data
        group: www-data
        mode: '0644'
        
    - name: Nginx-Site-Konfiguration erstellen
      template:
        src: ../templates/nginx-site.conf.j2
        dest: "/etc/nginx/sites-available/{{ domain_name }}"
        backup: true
      notify: reload nginx
      
    - name: Default-Site deaktivieren
      file:
        path: /etc/nginx/sites-enabled/default
        state: absent
      notify: reload nginx
      
    - name: Site aktivieren
      file:
        src: "/etc/nginx/sites-available/{{ domain_name }}"
        dest: "/etc/nginx/sites-enabled/{{ domain_name }}"
        state: link
      notify: reload nginx
      
    - name: SSL-Verzeichnisse erstellen (falls SSL aktiviert)
      file:
        path: "{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - /etc/ssl/certs
        - /etc/ssl/private
      when: ssl_enabled
      
    - name: Self-signed SSL-Zertifikat erstellen (Development)
      command: >
        openssl req -x509 -nodes -days 365 -newkey rsa:2048
        -keyout {{ ssl_private_key_path }}
        -out {{ ssl_certificate_path }}
        -subj "/C=DE/ST=State/L=City/O=Organization/CN={{ domain_name }}"
      args:
        creates: "{{ ssl_certificate_path }}"
      when: ssl_enabled
      
    - name: Firewall-Regeln konfigurieren
      ufw:
        rule: allow
        port: "{{ item }}"
        proto: tcp
      loop:
        - "{{ nginx_port }}"
        - "{{ ssl_port if ssl_enabled else [] }}"
      when: firewall_enabled and ansible_os_family == "Debian"
      
    - name: Nginx-Service starten und aktivieren
      systemd:
        name: nginx
        state: started
        enabled: true
        daemon_reload: true
        
    - name: Nginx-Konfiguration testen
      command: nginx -t
      register: nginx_test
      changed_when: false
      
    - name: Nginx-Test-Ergebnis anzeigen
      debug:
        msg: "✅ Nginx-Konfiguration ist gültig"
      when: nginx_test.rc == 0
      
  handlers:
    - name: reload nginx
      systemd:
        name: nginx
        state: reloaded
EOF

    log_success "Webserver-Template erstellt: $template_dir"
    echo
    echo "Template-Dateien:"
    echo "• Playbook: playbooks/webserver-setup.yml"
    echo "• Inventory: inventory/hosts.yml"  
    echo "• Variables: vars/main.yml"
    echo "• Nginx-Config: templates/nginx-site.conf.j2"
    echo "• Website: files/index.html"
    echo
    echo "Ausführung:"
    echo "cd $template_dir"
    echo "ansible-playbook playbooks/webserver-setup.yml -i inventory/hosts.yml"
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
    show_playbook_templates
}

# 📈 PERFORMANCE ANALYTICS
show_performance_analytics() {
    clear
    echo -e "${BRIGHT_PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_PURPLE}║${NC}                    ${WHITE}📈 PERFORMANCE ANALYTICS${NC}                        ${BRIGHT_PURPLE}║${NC}"
    echo -e "${BRIGHT_PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Analytics initialisieren falls noch nicht geschehen
    init_analytics
    
    echo
    echo -e "${PURPLE}┌─ 📊 ANALYTICS DASHBOARD ──────────────────────────────────────────────┐${NC}"
    
    if [ ! -f "$PERFORMANCE_LOG" ] || [ $(wc -l < "$PERFORMANCE_LOG") -le 1 ]; then
        echo -e "${PURPLE}│${NC} Noch keine Performance-Daten verfügbar.                           ${PURPLE}│${NC}"
        echo -e "${PURPLE}│${NC} Führe Playbooks aus um Daten zu sammeln.                          ${PURPLE}│${NC}"
    else
        show_performance_overview
    fi
    
    echo -e "${PURPLE}└─────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    echo -e "${BRIGHT_CYAN}┌─ 🎮 ANALYTICS AKTIONEN ───────────────────────────────────────────────┐${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}1)${NC} 📊 Performance-Dashboard anzeigen                             ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}2)${NC} 📈 Ausführungszeiten-Trends                                   ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}3)${NC} 🔍 Detaillierte Playbook-Analyse                             ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}4)${NC} 🎯 Performance-Hotspots identifizieren                       ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}5)${NC} 💡 Optimierungsvorschläge generieren                          ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}6)${NC} 📋 Benchmark-Tests ausführen                                  ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}7)${NC} 📤 Analytics-Report exportieren                               ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}8)${NC} 🧹 Analytics-Daten verwalten                                  ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}│${NC} ${WHITE}9)${NC} 🔙 Zurück zum Hauptmenü                                       ${BRIGHT_CYAN}│${NC}"
    echo -e "${BRIGHT_CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    read -p "$(echo -e "${WHITE}Wähle eine Aktion: ${NC}")" analytics_action
    
    case $analytics_action in
        1) show_performance_dashboard ;;
        2) show_execution_trends ;;
        3) analyze_playbook_details ;;
        4) identify_performance_hotspots ;;
        5) generate_optimization_suggestions ;;
        6) run_benchmark_tests ;;
        7) export_analytics_report ;;
        8) manage_analytics_data ;;
        9) return 0 ;;
        *) 
            echo -e "${RED}❌ Ungültige Auswahl${NC}"
            sleep 2
            show_performance_analytics
            ;;
    esac
}

show_performance_overview() {
    if [ ! -f "$PERFORMANCE_LOG" ] || [ $(wc -l < "$PERFORMANCE_LOG") -le 1 ]; then
        echo -e "${PURPLE}│${NC} Keine Performance-Daten verfügbar                                 ${PURPLE}│${NC}"
        return
    fi
    
    # Statistiken berechnen
    local total_runs=$(tail -n +2 "$PERFORMANCE_LOG" | wc -l)
    local avg_duration=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$3; count++} END {printf "%.2f", count > 0 ? sum/count : 0}')
    local total_tasks=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$4; count++} END {printf "%.0f", count > 0 ? sum/count : 0}')
    local success_rate=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{total++; if($6==0) success++} END {printf "%.1f", total > 0 ? (success*100)/total : 0}')
    
    echo -e "${PURPLE}│${NC} ${WHITE}Total Runs:${NC} %-10s ${WHITE}Avg Duration:${NC} %-10s sec         ${PURPLE}│${NC}" "$total_runs" "$avg_duration"
    echo -e "${PURPLE}│${NC} ${WHITE}Avg Tasks:${NC} %-11s ${WHITE}Success Rate:${NC} %-10s %%          ${PURPLE}│${NC}" "$total_tasks" "$success_rate"
    
    # Letzte 5 Ausführungen
    echo -e "${PURPLE}├─────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${PURPLE}│${NC} ${WHITE}Letzte Ausführungen:${NC}                                           ${PURPLE}│${NC}"
    tail -n 5 "$PERFORMANCE_LOG" | while IFS=',' read -r timestamp playbook duration tasks changed failed ok skipped host container; do
        local status="✅"
        if [ "$failed" -gt 0 ]; then
            status="❌"
        elif [ "$changed" -eq 0 ]; then
            status="⚡"
        fi
        
        local short_time=$(echo "$timestamp" | cut -d'T' -f2 | cut -d'+' -f1 | cut -d':' -f1,2)
        local short_playbook=$(basename "$playbook" .yml)
        printf "${PURPLE}│${NC} %s %-8s %-20s %6ss %2dt ${PURPLE}│${NC}\n" "$status" "$short_time" "$short_playbook" "$duration" "$tasks"
    done
}

show_performance_dashboard() {
    clear
    echo -e "${BRIGHT_PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_PURPLE}║${NC}                   ${WHITE}📊 PERFORMANCE DASHBOARD${NC}                        ${BRIGHT_PURPLE}║${NC}"
    echo -e "${BRIGHT_PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    if [ ! -f "$PERFORMANCE_LOG" ] || [ $(wc -l < "$PERFORMANCE_LOG") -le 1 ]; then
        echo
        echo -e "${YELLOW}┌─ ℹ️  KEINE DATEN VERFÜGBAR ────────────────────────────────────────────┐${NC}"
        echo -e "${YELLOW}│${NC} Noch keine Performance-Daten gesammelt.                           ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC} Führe Playbooks aus um Analytics zu aktivieren.                   ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC}                                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC} Automatisches Tracking für:                                       ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC} • Ausführungszeiten                                               ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC} • Task-Statistiken                                                ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC} • Erfolgsraten                                                    ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC} • Resource-Verbrauch                                              ${YELLOW}│${NC}"
        echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────────┘${NC}"
        
        read -p "$(echo -e "${CYAN}Benchmark-Test ausführen um Daten zu generieren? (Y/n): ${NC}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            run_benchmark_tests
            return
        fi
        
        read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
        show_performance_analytics
        return
    fi
    
    echo
    
    # Gesamt-Statistiken
    local total_runs=$(tail -n +2 "$PERFORMANCE_LOG" | wc -l)
    local avg_duration=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$3} END {printf "%.2f", NR > 0 ? sum/NR : 0}')
    local min_duration=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' 'NR==1{min=$3} {if($3<min) min=$3} END {printf "%.2f", min}')
    local max_duration=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{if($3>max) max=$3} END {printf "%.2f", max}')
    local total_tasks=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$4} END {printf "%.0f", sum}')
    local total_changed=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$5} END {printf "%.0f", sum}')
    local total_failed=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$6} END {printf "%.0f", sum}')
    local success_rate=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{total++; if($6==0) success++} END {printf "%.1f", total > 0 ? (success*100)/total : 0}')
    
    echo -e "${BLUE}┌─ 📈 AUSFÜHRUNGSSTATISTIKEN ───────────────────────────────────────────┐${NC}"
    printf "${BLUE}│${NC} ${WHITE}Total Runs:${NC} %-10s ${WHITE}Erfolgsrate:${NC} %-15s      ${BLUE}│${NC}\n" "$total_runs" "${success_rate}%"
    printf "${BLUE}│${NC} ${WHITE}Avg Dauer:${NC} %-11s ${WHITE}Min/Max:${NC} %-10s / %-6s s ${BLUE}│${NC}\n" "${avg_duration}s" "${min_duration}" "${max_duration}"
    printf "${BLUE}│${NC} ${WHITE}Total Tasks:${NC} %-9s ${WHITE}Davon geändert:${NC} %-12s    ${BLUE}│${NC}\n" "$total_tasks" "$total_changed"
    printf "${BLUE}│${NC} ${WHITE}Fehlgeschlagen:${NC} %-6s ${WHITE}Erfolgreiche Tasks:${NC} %-9s    ${BLUE}│${NC}\n" "$total_failed" "$((total_tasks - total_failed))"
    echo -e "${BLUE}└─────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    
    # Playbook-Rankings
    echo -e "${GREEN}┌─ 🏆 TOP PLAYBOOKS (nach Häufigkeit) ──────────────────────────────────┐${NC}"
    tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{print $2}' | sort | uniq -c | sort -nr | head -5 | \
    while read count playbook; do
        local short_name=$(basename "$playbook" .yml | cut -c1-25)
        printf "${GREEN}│${NC} %-3s mal: %-35s                    ${GREEN}│${NC}\n" "$count" "$short_name"
    done
    echo -e "${GREEN}└─────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    
    # Performance-Trends (ASCII-Chart)
    echo -e "${PURPLE}┌─ 📊 AUSFÜHRUNGSZEIT-TREND (letzte 10 Runs) ───────────────────────────┐${NC}"
    local trend_data=$(tail -n 10 "$PERFORMANCE_LOG" | awk -F',' '{print $3}')
    draw_ascii_chart "$trend_data"
    echo -e "${PURPLE}└─────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    
    # Container/Host-Verteilung
    echo -e "${CYAN}┌─ 🏠 AUSFÜHRUNGS-UMGEBUNGEN ────────────────────────────────────────────┐${NC}"
    tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{
        if ($10 != "local") container_runs++
        else local_runs++
        hosts[$9]++
    } END {
        printf "│ Container-Runs: %-10s Lokale Runs: %-15s │\n", container_runs+0, local_runs+0
        for (host in hosts) {
            printf "│ Host: %-15s Runs: %-25s │\n", host, hosts[host]
        }
    }' | head -5
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────┘${NC}"
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
    show_performance_analytics
}

draw_ascii_chart() {
    local data="$1"
    local max_val=$(echo "$data" | sort -n | tail -1)
    local max_width=50
    
    if [ -z "$max_val" ] || [ "$max_val" = "0" ]; then
        echo -e "${PURPLE}│${NC} Keine Daten für Chart verfügbar                               ${PURPLE}│${NC}"
        return
    fi
    
    echo "$data" | nl | while read num value; do
        local bar_width=$(echo "scale=0; $value * $max_width / $max_val" | bc 2>/dev/null || echo "1")
        local bar=""
        
        for ((i=0; i<bar_width; i++)); do
            bar="${bar}█"
        done
        
        printf "${PURPLE}│${NC} %2d: %-6.2fs [%-50s] ${PURPLE}│${NC}\n" "$num" "$value" "$bar"
    done
}

run_benchmark_tests() {
    echo
    echo -e "${BRIGHT_YELLOW}=== 📋 BENCHMARK-TESTS ===${NC}"
    echo
    
    log_info "Führe Benchmark-Tests aus um Performance-Daten zu sammeln..."
    
    # Test-Playbooks erstellen falls nicht vorhanden
    local benchmark_dir="$HOME/ansible-projekte/benchmarks"
    mkdir -p "$benchmark_dir"/{playbooks,inventory}
    
    # Benchmark-Inventory
    cat > "$benchmark_dir/inventory/hosts.yml" << 'EOF'
all:
  children:
    benchmark:
      hosts:
        localhost:
          ansible_connection: local
EOF

    # Leichter Test
    cat > "$benchmark_dir/playbooks/light-benchmark.yml" << 'EOF'
---
- name: Light Benchmark Test
  hosts: localhost
  connection: local
  gather_facts: true
  
  tasks:
    - name: Create test directory
      file:
        path: /tmp/ansible-benchmark
        state: directory
        
    - name: Create test files
      copy:
        content: "Benchmark test {{ item }}"
        dest: "/tmp/ansible-benchmark/test-{{ item }}.txt"
      loop: "{{ range(1, 6) | list }}"
      
    - name: Check files exist
      stat:
        path: "/tmp/ansible-benchmark/test-{{ item }}.txt"
      loop: "{{ range(1, 6) | list }}"
      register: file_check
      
    - name: Cleanup test files
      file:
        path: /tmp/ansible-benchmark
        state: absent
EOF

    # Mittlerer Test
    cat > "$benchmark_dir/playbooks/medium-benchmark.yml" << 'EOF'
---
- name: Medium Benchmark Test
  hosts: localhost
  connection: local
  gather_facts: true
  
  tasks:
    - name: Create test structure
      file:
        path: "/tmp/ansible-benchmark/{{ item }}"
        state: directory
      loop:
        - dir1
        - dir2
        - dir3
        
    - name: Install test package
      package:
        name: curl
        state: present
      become: true
      
    - name: Generate test data
      copy:
        content: |
          Benchmark test data
          Generated at: {{ ansible_date_time.iso8601 }}
          Host: {{ inventory_hostname }}
          User: {{ ansible_user_id }}
          {% for i in range(10) %}
          Line {{ i }}: Test data for performance benchmark
          {% endfor %}
        dest: "/tmp/ansible-benchmark/benchmark-data.txt"
        
    - name: Process test data
      shell: "wc -l /tmp/ansible-benchmark/benchmark-data.txt"
      register: line_count
      
    - name: Verify results
      debug:
        msg: "Processed {{ line_count.stdout.split()[0] }} lines"
        
    - name: Cleanup
      file:
        path: /tmp/ansible-benchmark
        state: absent
EOF

    # Schwerer Test
    cat > "$benchmark_dir/playbooks/heavy-benchmark.yml" << 'EOF'
---
- name: Heavy Benchmark Test
  hosts: localhost
  connection: local
  gather_facts: true
  
  tasks:
    - name: Create large test structure
      file:
        path: "/tmp/ansible-benchmark/{{ item.dir }}/{{ item.subdir }}"
        state: directory
      loop:
        - { dir: "test1", subdir: "sub1" }
        - { dir: "test1", subdir: "sub2" }
        - { dir: "test2", subdir: "sub1" }
        - { dir: "test2", subdir: "sub2" }
        - { dir: "test3", subdir: "sub1" }
        
    - name: Generate large files
      copy:
        content: |
          {% for i in range(100) %}
          Benchmark line {{ i }}: {{ ansible_date_time.iso8601 }}
          {% endfor %}
        dest: "/tmp/ansible-benchmark/test{{ item }}/sub{{ item }}/large-file.txt"
      loop: "{{ range(1, 4) | list }}"
      
    - name: Process multiple files
      shell: "find /tmp/ansible-benchmark -name '*.txt' -exec wc -l {} +"
      register: total_lines
      
    - name: Install additional packages
      package:
        name: "{{ item }}"
        state: present
      loop:
        - tree
        - htop
      become: true
      
    - name: Run system commands
      command: "{{ item }}"
      loop:
        - "ls -la /tmp/ansible-benchmark"
        - "du -sh /tmp/ansible-benchmark"
        - "find /tmp/ansible-benchmark -type f | wc -l"
      register: command_results
      
    - name: Show results
      debug:
        msg: "Total lines in files: {{ total_lines.stdout_lines[-1] }}"
        
    - name: Cleanup large test
      file:
        path: /tmp/ansible-benchmark
        state: absent
EOF

    # Benchmark-Tests ausführen
    local tests=("light-benchmark" "medium-benchmark" "heavy-benchmark")
    local test_names=("🟢 Leicht" "🟡 Mittel" "🔴 Schwer")
    
    cd "$benchmark_dir"
    
    for i in "${!tests[@]}"; do
        local test="${tests[$i]}"
        local name="${test_names[$i]}"
        
        echo
        log_info "Führe $name Benchmark aus..."
        
        local start_time=$(date +%s.%N)
        
        # Playbook mit Performance-Tracking ausführen
        ansible-playbook "playbooks/${test}.yml" -i inventory/hosts.yml -v > "/tmp/benchmark-${test}.log" 2>&1
        local exit_code=$?
        
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc)
        
        # Statistiken aus Log extrahieren
        local task_count=$(grep -c "TASK \[" "/tmp/benchmark-${test}.log" || echo "0")
        local changed_count=$(grep -c "changed:" "/tmp/benchmark-${test}.log" || echo "0")
        local failed_count=$(grep -c "failed:" "/tmp/benchmark-${test}.log" || echo "0")
        local ok_count=$(grep -c "ok:" "/tmp/benchmark-${test}.log" || echo "0")
        
        # Performance-Daten loggen
        log_performance "${test}.yml" "$duration" "$task_count,$changed_count,$failed_count,$ok_count,0" "localhost" "benchmark"
        
        if [ $exit_code -eq 0 ]; then
            log_success "$name Benchmark abgeschlossen (${duration}s)"
        else
            log_warning "$name Benchmark hatte Probleme"
        fi
        
        # Progress anzeigen
        show_progress_bar "$((i+1))" "${#tests[@]}" "Benchmark" "$(( (i+1) * 100 / ${#tests[@]} ))% complete" "$GREEN"
        echo
        
        sleep 1
    done
    
    echo
    log_success "Alle Benchmark-Tests abgeschlossen!"
    log_info "Performance-Daten wurden in Analytics gespeichert"
    
    # Cleanup
    rm -f /tmp/benchmark-*.log
    
    read -p "$(echo -e "${CYAN}Performance-Dashboard anzeigen? (Y/n): ${NC}")" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        show_performance_dashboard
    else
        show_performance_analytics
    fi
}

# Erweiterte Menü-Anzeige mit neuen Features
show_enhanced_menu() {
    echo
    echo -e "${BRIGHT_CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_CYAN}║${NC}                        ${WHITE}📋 INSTALLATIONS-OPTIONEN${NC}                        ${BRIGHT_CYAN}║${NC}"
    echo -e "${BRIGHT_CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    
    # Lokale Installationen
    echo -e "${BRIGHT_CYAN}║${NC} ${BRIGHT_YELLOW}📍 LOKALE INSTALLATIONEN${NC}                                          ${BRIGHT_CYAN}║${NC}"
    print_separator "$BRIGHT_CYAN"
    print_menu_item "1" "🔧" "Basis-Installation" "Ansible + essentials" "$BRIGHT_CYAN"
    print_menu_item "2" "⚡" "Vollständige Installation" "+ Docker, VSCode, Tools" "$BRIGHT_CYAN"
    print_menu_item "3" "📦" "Minimale Installation" "nur Ansible" "$BRIGHT_CYAN"
    print_menu_item "4" "🎛️ " "Custom Installation" "einzeln auswählen" "$BRIGHT_CYAN"
    
    print_separator "$BRIGHT_CYAN"
    echo -e "${BRIGHT_CYAN}║${NC} ${BRIGHT_GREEN}🐳 CONTAINER-INSTALLATIONEN${NC}                                      ${BRIGHT_CYAN}║${NC}"
    print_separator "$BRIGHT_CYAN"
    print_menu_item "5" "🧪" "Testumgebung" "einfache Test-Container" "$BRIGHT_CYAN"
    print_menu_item "6" "🔒" "Docker-Container" "isolierte Installation" "$BRIGHT_CYAN"
    
    print_separator "$BRIGHT_CYAN"
    echo -e "${BRIGHT_CYAN}║${NC} ${BRIGHT_PURPLE}🚀 AUTO-INSTALLATIONEN (KW-Container)${NC}                           ${BRIGHT_CYAN}║${NC}"
    print_separator "$BRIGHT_CYAN"
    print_menu_item "7" "🐋" "Docker AUTO" "KW-Container + Vollinstallation" "$BRIGHT_CYAN"
    print_menu_item "8" "🐳" "Podman AUTO (ROOTLESS)" "KEIN sudo erforderlich!" "$BRIGHT_CYAN"
    
    print_separator "$BRIGHT_CYAN"
    echo -e "${BRIGHT_CYAN}║${NC} ${BRIGHT_BLUE}🛠️  VERWALTUNG & TOOLS${NC}                                            ${BRIGHT_CYAN}║${NC}"
    print_separator "$BRIGHT_CYAN"
    print_menu_item "9" "📊" "Container-Management" "anzeigen/verwalten/löschen" "$BRIGHT_CYAN"
    print_menu_item "10" "🎨" "Progress-Demo" "Ladebalken-Features testen" "$BRIGHT_CYAN"
    
    print_separator "$BRIGHT_CYAN"
    echo -e "${BRIGHT_CYAN}║${NC} ${BRIGHT_RED}🚀 NEUE ADVANCED FEATURES${NC}                                       ${BRIGHT_CYAN}║${NC}"
    print_separator "$BRIGHT_CYAN"
    print_menu_item "11" "🩺" "Health Dashboard" "System & Container Monitoring" "$BRIGHT_CYAN"
    print_menu_item "12" "🌐" "Remote Management" "Container auf anderen Hosts" "$BRIGHT_CYAN"
    print_menu_item "13" "🎮" "Playbook Builder" "Interaktive Playbook-Erstellung" "$BRIGHT_CYAN"
    print_menu_item "14" "📈" "Performance Analytics" "Ausführungszeiten & Trends" "$BRIGHT_CYAN"
    
    print_separator "$BRIGHT_CYAN"
    print_menu_item "15" "❌" "Beenden" "Script verlassen" "$BRIGHT_CYAN"
    
    echo -e "${BRIGHT_CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Empfehlungs-Card mit neuen Features
    echo
    echo -e "${GREEN}┌─ 💡 EMPFEHLUNGEN & NEUE FEATURES ─────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│${NC} ${WHITE}Neu hier?${NC}        → Option ${BRIGHT_GREEN}8${NC} (Podman rootless, kein sudo)      ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC} ${WHITE}Docker-Fan?${NC}      → Option ${BRIGHT_BLUE}7${NC} (Docker mit Auto-Fix)              ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC} ${WHITE}Monitoring?${NC}      → Option ${BRIGHT_RED}11${NC} (Health Dashboard) 🩺            ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC} ${WHITE}Remote-Hosts?${NC}    → Option ${BRIGHT_RED}12${NC} (Remote Management) 🌐           ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC} ${WHITE}Playbook-Hilfe?${NC}  → Option ${BRIGHT_RED}13${NC} (Interaktiver Builder) 🎮       ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC} ${WHITE}Performance?${NC}     → Option ${BRIGHT_RED}14${NC} (Analytics Dashboard) 📈        ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC} ${WHITE}UI-Demo?${NC}         → Option ${BRIGHT_CYAN}10${NC} (Progress-Bars & Spinner)          ${GREEN}│${NC}"
    echo -e "${GREEN}└─────────────────────────────────────────────────────────────────────┘${NC}"
    echo
}

print_separator() {
    local color="${1:-$GRAY}"
    echo -e "${color}├$(printf '─%.0s' $(seq 1 68))┤${NC}"
}

print_menu_item() {
    local number="$1"
    local icon="$2"
    local title="$3"
    local description="$4"
    local color="${5:-$CYAN}"
    
    printf "${color}│${NC} ${WHITE}%2s${NC} ${color}│${NC} %s ${WHITE}%-20s${NC} ${GRAY}%s${NC}\n" \
           "$number" "$icon" "$title" "$description"
}

# Helper-Funktionen für Performance Analytics
show_execution_trends() {
    clear
    echo -e "${BRIGHT_PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_PURPLE}║${NC}                   ${WHITE}📈 AUSFÜHRUNGSZEIT-TRENDS${NC}                       ${BRIGHT_PURPLE}║${NC}"
    echo -e "${BRIGHT_PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    if [ ! -f "$PERFORMANCE_LOG" ] || [ $(wc -l < "$PERFORMANCE_LOG") -le 1 ]; then
        echo
        echo -e "${YELLOW}Keine Trend-Daten verfügbar${NC}"
        read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
        show_performance_analytics
        return
    fi
    
    echo
    echo -e "${PURPLE}=== TREND-ANALYSE (letzte 30 Tage) ===${NC}"
    
    # Tägliche Durchschnitte berechnen
    tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{
        date = substr($1, 1, 10)
        duration[date] += $3
        count[date]++
    } END {
        for (d in duration) {
            printf "%s,%.2f\n", d, duration[d]/count[d]
        }
    }' | sort | tail -7 | while IFS=',' read date avg_duration; do
        local bar_width=$(echo "scale=0; $avg_duration * 30 / 10" | bc 2>/dev/null || echo "1")
        local bar=""
        for ((i=0; i<bar_width && i<30; i++)); do
            bar="${bar}█"
        done
        printf "%-12s %6.2fs [%-30s]\n" "$date" "$avg_duration" "$bar"
    done
    
    echo
    echo -e "${PURPLE}=== PLAYBOOK PERFORMANCE RANKING ===${NC}"
    tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{
        playbook = $2
        duration[playbook] += $3
        count[playbook]++
    } END {
        for (p in duration) {
            printf "%.2f,%s,%d\n", duration[p]/count[p], p, count[p]
        }
    }' | sort -n | while IFS=',' read avg_duration playbook count; do
        local short_name=$(basename "$playbook" .yml | cut -c1-25)
        printf "%-25s: %6.2fs (%-2d runs)\n" "$short_name" "$avg_duration" "$count"
    done | tail -10
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
    show_performance_analytics
}

identify_performance_hotspots() {
    clear
    echo -e "${BRIGHT_RED}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_RED}║${NC}                   ${WHITE}🎯 PERFORMANCE HOTSPOTS${NC}                         ${BRIGHT_RED}║${NC}"
    echo -e "${BRIGHT_RED}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    if [ ! -f "$PERFORMANCE_LOG" ] || [ $(wc -l < "$PERFORMANCE_LOG") -le 1 ]; then
        echo
        echo -e "${YELLOW}Keine Performance-Daten für Analyse verfügbar${NC}"
        read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
        show_performance_analytics
        return
    fi
    
    echo
    echo -e "${RED}🔍 IDENTIFIZIERTE HOTSPOTS:${NC}"
    echo
    
    # Langsame Playbooks (>30s)
    echo -e "${YELLOW}⚠️  LANGSAME PLAYBOOKS (>30s):${NC}"
    tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '$3 > 30 {
        printf "   📋 %s: %.2fs (%d tasks)\n", $2, $3, $4
    }' | sort -k3 -nr | head -5
    
    echo
    
    # Fehlerhafte Ausführungen
    echo -e "${RED}❌ FEHLGESCHLAGENE AUSFÜHRUNGEN:${NC}"
    tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '$6 > 0 {
        printf "   📋 %s: %d failed tasks (%.2fs)\n", $2, $6, $3
    }' | head -5
    
    echo
    
    # Performance-Regression (Playbooks die langsamer geworden sind)
    echo -e "${ORANGE}📉 PERFORMANCE-REGRESSIONEN:${NC}"
    tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{
        playbook = $2
        if (count[playbook] == 0) {
            first_duration[playbook] = $3
        }
        last_duration[playbook] = $3
        count[playbook]++
    } END {
        for (p in count) {
            if (count[p] > 2 && last_duration[p] > first_duration[p] * 1.5) {
                printf "   📋 %s: %.2fs → %.2fs (+%.1f%%)\n", 
                       p, first_duration[p], last_duration[p], 
                       ((last_duration[p] - first_duration[p]) / first_duration[p] * 100)
            }
        }
    }' | head -5
    
    echo
    
    # Resource-intensive Hosts
    echo -e "${PURPLE}🖥️  RESOURCE-INTENSIVE HOSTS:${NC}"
    tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{
        host = $9
        duration[host] += $3
        tasks[host] += $4
        count[host]++
    } END {
        for (h in duration) {
            if (count[h] > 1) {
                printf "   🖥️  %s: %.2fs avg (%.0f tasks avg, %d runs)\n", 
                       h, duration[h]/count[h], tasks[h]/count[h], count[h]
            }
        }
    }' | sort -k3 -nr | head -3
    
    echo
    echo -e "${GREEN}💡 OPTIMIERUNGSEMPFEHLUNGEN:${NC}"
    
    # Automatische Empfehlungen generieren
    local slow_playbooks=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '$3 > 30' | wc -l)
    local total_failed=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$6} END {print sum+0}')
    local avg_tasks=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$4; count++} END {printf "%.0f", count > 0 ? sum/count : 0}')
    
    if [ "$slow_playbooks" -gt 0 ]; then
        echo "   🚀 Verwende Parallel-Ausführung mit 'forks' Parameter"
        echo "   ⚡ Implementiere Fact-Caching für wiederholte Ausführungen"
        echo "   📦 Aktiviere Pipelining in ansible.cfg"
    fi
    
    if [ "$total_failed" -gt 0 ]; then
        echo "   🛡️  Implementiere bessere Fehlerbehandlung mit 'rescue' Blöcken"
        echo "   🔍 Verwende 'check_mode' vor produktiven Ausführungen"
    fi
    
    if [ "$avg_tasks" -gt 20 ]; then
        echo "   📋 Teile große Playbooks in kleinere, fokussierte Rollen auf"
        echo "   🎯 Verwende Tags für selektive Ausführung"
    fi
    
    echo "   📈 Aktiviere Performance-Callbacks für detailliertere Metriken"
    echo "   🔧 Optimiere Inventory-Struktur und -Gruppierung"
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
    show_performance_analytics
}

generate_optimization_suggestions() {
    clear
    echo -e "${BRIGHT_GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_GREEN}║${NC}                  ${WHITE}💡 OPTIMIERUNGSVORSCHLÄGE${NC}                        ${BRIGHT_GREEN}║${NC}"
    echo -e "${BRIGHT_GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    echo -e "${GREEN}Analysiere deine Ansible-Umgebung und generiere Optimierungsvorschläge...${NC}"
    echo
    
    # Ansible-Konfiguration analysieren
    echo -e "${BLUE}🔧 KONFIGURATIONSOPTIMIERUNGEN:${NC}"
    echo
    
    if [ -f "$HOME/.ansible/ansible.cfg" ]; then
        local config_file="$HOME/.ansible/ansible.cfg"
        
        # Prüfe wichtige Performance-Settings
        if ! grep -q "forks" "$config_file"; then
            echo "   ⚡ Füge 'forks = 10' hinzu für parallele Ausführung"
        fi
        
        if ! grep -q "pipelining" "$config_file"; then
            echo "   🚀 Aktiviere 'pipelining = True' für SSH-Optimierung"
        fi
        
        if ! grep -q "fact_caching" "$config_file"; then
            echo "   📦 Aktiviere Fact-Caching: 'fact_caching = memory'"
        fi
        
        if ! grep -q "host_key_checking" "$config_file"; then
            echo "   🔐 Setze 'host_key_checking = False' für Development"
        fi
        
        echo "   ✅ Ansible-Konfiguration gefunden und analysiert"
    else
        echo "   ❌ Keine ansible.cfg gefunden - erstelle optimierte Konfiguration"
        
        read -p "   Optimierte ansible.cfg erstellen? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            create_optimized_ansible_config
        fi
    fi
    
    echo
    echo -e "${PURPLE}📁 PROJEKT-STRUKTUR OPTIMIERUNGEN:${NC}"
    echo
    
    # Projekt-Struktur analysieren
    if [ -d "$HOME/ansible-projekte" ]; then
        local project_count=$(find "$HOME/ansible-projekte" -maxdepth 1 -type d | wc -l)
        project_count=$((project_count - 1))
        
        echo "   📊 $project_count Projekte gefunden"
        
        # Prüfe auf Best Practices
        local projects_with_roles=0
        local projects_with_vars=0
        local projects_with_inventory=0
        
        for project_dir in "$HOME/ansible-projekte"/*; do
            if [ -d "$project_dir" ]; then
                [ -d "$project_dir/roles" ] && projects_with_roles=$((projects_with_roles + 1))
                [ -d "$project_dir/vars" ] && projects_with_vars=$((projects_with_vars + 1))
                [ -d "$project_dir/inventory" ] && projects_with_inventory=$((projects_with_inventory + 1))
            fi
        done
        
        if [ $projects_with_roles -lt $project_count ]; then
            echo "   🎭 Nutze Roles für wiederverwendbare Funktionalität"
        fi
        
        if [ $projects_with_vars -lt $project_count ]; then
            echo "   📝 Lagere Variablen in separate Dateien aus"
        fi
        
        if [ $projects_with_inventory -lt $project_count ]; then
            echo "   📋 Verwende strukturierte Inventory-Dateien"
        fi
        
        echo "   💡 Implementiere Git-Versionierung für Playbooks"
        echo "   🔍 Nutze ansible-lint für Code-Qualität"
    else
        echo "   📁 Erstelle strukturierte Projekt-Verzeichnisse"
    fi
    
    echo
    echo -e "${CYAN}🐳 CONTAINER-OPTIMIERUNGEN:${NC}"
    echo
    
    # Container-Performance analysieren
    if [ -f "$PERFORMANCE_LOG" ]; then
        local container_runs=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '$10 != "local"' | wc -l)
        local local_runs=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '$10 == "local"' | wc -l)
        
        if [ $container_runs -gt 0 ]; then
            echo "   📊 $container_runs Container-Ausführungen vs $local_runs lokale"
            
            local avg_container_time=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '$10 != "local" {sum+=$3; count++} END {printf "%.2f", count > 0 ? sum/count : 0}')
            local avg_local_time=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '$10 == "local" {sum+=$3; count++} END {printf "%.2f", count > 0 ? sum/count : 0}')
            
            echo "   ⏱️  Durchschnitt Container: ${avg_container_time}s, Lokal: ${avg_local_time}s"
            
            if (( $(echo "$avg_container_time > $avg_local_time * 1.5" | bc -l) )); then
                echo "   🚀 Container-Performance optimieren:"
                echo "      • Verwende Volume-Mounts für wiederverwendbare Daten"
                echo "      • Nutze Container-spezifische SSH-Konfiguration"
                echo "      • Implementiere Container-Warmup für bessere Startzeiten"
            fi
        fi
    fi
    
    # Hardware-spezifische Empfehlungen
    echo
    echo -e "${YELLOW}🖥️  HARDWARE-OPTIMIERUNGEN:${NC}"
    echo
    
    local cpu_cores=$(nproc)
    local total_memory=$(free -g | awk '/^Mem:/{print $2}')
    
    echo "   💻 System: $cpu_cores CPU-Kerne, ${total_memory}GB RAM"
    
    if [ $cpu_cores -gt 4 ]; then
        echo "   ⚡ Nutze mehr parallele Forks: forks = $((cpu_cores * 2))"
    fi
    
    if [ $total_memory -gt 8 ]; then
        echo "   🧠 Aktiviere erweiterte Fact-Caching-Strategien"
        echo "   🐳 Führe mehrere Container parallel aus"
    fi
    
    # SSH-Optimierungen
    echo
    echo -e "${RED}🔐 SSH-OPTIMIERUNGEN:${NC}"
    echo
    
    if [ -f "$HOME/.ssh/config" ]; then
        echo "   ✅ SSH-Config gefunden"
        
        if ! grep -q "ControlMaster" "$HOME/.ssh/config"; then
            echo "   🚀 SSH-Multiplexing aktivieren für bessere Performance"
        fi
    else
        echo "   📝 Erstelle SSH-Config für optimierte Verbindungen"
    fi
    
    echo "   🔑 Nutze SSH-Agent für automatische Schlüsselverwaltung"
    echo "   ⚡ Implementiere SSH-Bastion-Hosts für Remote-Zugriff"
    
    # Monitoring-Empfehlungen
    echo
    echo -e "${BRIGHT_PURPLE}📊 MONITORING & LOGGING:${NC}"
    echo
    
    echo "   📈 Aktiviere Callback-Plugins für erweiterte Metriken"
    echo "   📝 Implementiere strukturiertes Logging"
    echo "   🔔 Setze Alerting für fehlgeschlagene Playbooks auf"
    echo "   📊 Integriere mit Prometheus/Grafana für Dashboards"
    
    # Automatische Konfiguration anbieten
    echo
    echo -e "${BRIGHT_GREEN}🛠️  AUTOMATISCHE OPTIMIERUNG:${NC}"
    echo
    
    read -p "Soll ich automatisch eine optimierte Ansible-Konfiguration erstellen? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        create_optimized_ansible_config
        create_performance_monitoring_setup
    fi
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
    show_performance_analytics
}

create_optimized_ansible_config() {
    local config_file="$HOME/.ansible/ansible.cfg"
    local backup_file="${config_file}.backup.$(date +%s)"
    
    # Backup der bestehenden Konfiguration
    if [ -f "$config_file" ]; then
        cp "$config_file" "$backup_file"
        log_info "Backup erstellt: $backup_file"
    fi
    
    mkdir -p "$HOME/.ansible"
    
    cat > "$config_file" << 'EOF'
[defaults]
# === PERFORMANCE OPTIMIZATIONS ===
# Parallele Ausführung
forks = 20
# SSH-Optimierung
pipelining = True
# Fact-Caching
gathering = smart
fact_caching = memory
fact_caching_timeout = 3600
# Host-Key-Checking (für Development)
host_key_checking = False

# === BASIC SETTINGS ===
inventory = ./inventory/hosts.yml
remote_user = ansible
private_key_file = ~/.ssh/id_rsa
stdout_callback = yaml
bin_ansible_callbacks = True
display_skipped_hosts = False
display_ok_hosts = True

# === RETRY & TIMEOUT ===
retry_files_enabled = False
timeout = 30
command_timeout = 60

# === LOGGING ===
log_path = ~/.ansible/ansible.log
force_color = True

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
# SSH-Performance-Optimierungen
ssh_args = -o ControlMaster=auto -o ControlPersist=300s -o PreferredAuthentications=publickey
control_path_dir = ~/.ansible/cp
pipelining = True
# SSH-Multiplexing
control_path = ~/.ansible/cp/%%h-%%p-%%r

[inventory]
# Inventory-Performance
cache = True
cache_plugin = memory
cache_timeout = 3600

[callback_profile_tasks]
# Task-Performance-Tracking
task_output_limit = 100
EOF
    
    # Control-Path-Verzeichnis erstellen
    mkdir -p "$HOME/.ansible/cp"
    
    log_success "Optimierte Ansible-Konfiguration erstellt: $config_file"
    log_info "Performance-Verbesserungen:"
    echo "  • 20 parallele Forks für schnellere Ausführung"
    echo "  • SSH-Pipelining und -Multiplexing aktiviert"
    echo "  • Smart-Gathering mit Memory-Caching"
    echo "  • Erweiterte Logging- und Retry-Konfiguration"
}

create_performance_monitoring_setup() {
    local monitoring_dir="$HOME/ansible-projekte/monitoring"
    mkdir -p "$monitoring_dir"/{playbooks,callbacks,scripts}
    
    # Performance-Callback-Plugin
    cat > "$monitoring_dir/callbacks/performance_monitor.py" << 'EOF'
"""
Ansible Performance Monitoring Callback Plugin
"""
import time
import json
import os
from ansible.plugins.callback import CallbackBase

class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'notification'
    CALLBACK_NAME = 'performance_monitor'
    
    def __init__(self):
        super(CallbackModule, self).__init__()
        self.task_start_time = {}
        self.play_start_time = None
        self.stats = {}
        
    def v2_playbook_on_play_start(self, play):
        self.play_start_time = time.time()
        
    def v2_runner_on_ok(self, result):
        self._record_task_result(result, 'ok')
        
    def v2_runner_on_failed(self, result, ignore_errors=False):
        self._record_task_result(result, 'failed')
        
    def v2_runner_on_skipped(self, result):
        self._record_task_result(result, 'skipped')
        
    def _record_task_result(self, result, status):
        task_name = result.task_name
        host = result._host.name
        
        if task_name not in self.stats:
            self.stats[task_name] = {}
        if host not in self.stats[task_name]:
            self.stats[task_name][host] = {'ok': 0, 'failed': 0, 'skipped': 0, 'duration': 0}
            
        self.stats[task_name][host][status] += 1
        
    def v2_playbook_on_stats(self, stats):
        # Performance-Statistiken ausgeben
        total_time = time.time() - self.play_start_time if self.play_start_time else 0
        
        performance_data = {
            'total_duration': total_time,
            'task_stats': self.stats,
            'host_stats': dict(stats.processed)
        }
        
        # In Analytics-Log schreiben
        analytics_file = os.path.expanduser('~/.ansible-analytics/callback-performance.json')
        os.makedirs(os.path.dirname(analytics_file), exist_ok=True)
        
        with open(analytics_file, 'a') as f:
            f.write(json.dumps(performance_data) + '\n')
EOF
    
    # Monitoring-Playbook
    cat > "$monitoring_dir/playbooks/system-monitoring.yml" << 'EOF'
---
- name: System Performance Monitoring
  hosts: localhost
  connection: local
  gather_facts: true
  
  tasks:
    - name: Collect system metrics
      shell: |
        echo "CPU: $(top -bn1 | grep Cpu | awk '{print $2}' | cut -d'%' -f1)"
        echo "Memory: $(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')"
        echo "Disk: $(df / | tail -1 | awk '{print $5}' | sed 's/%//')"
        echo "Load: $(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')"
      register: system_metrics
      
    - name: Display metrics
      debug:
        var: system_metrics.stdout_lines
        
    - name: Log performance data
      copy:
        content: |
          {{ ansible_date_time.iso8601 }},system_monitor,{{ system_metrics.stdout_lines | join(',') }}
        dest: ~/.ansible-analytics/system-monitoring.csv
        mode: '0644'
      delegate_to: localhost
EOF
    
    # Monitoring-Script
    cat > "$monitoring_dir/scripts/ansible-perf-monitor.sh" << 'EOF'
#!/bin/bash

# Ansible Performance Monitor
# Führe regelmäßige Performance-Checks aus

ANALYTICS_DIR="$HOME/.ansible-analytics"
LOG_FILE="$ANALYTICS_DIR/monitoring.log"

log_metric() {
    local metric="$1"
    local value="$2"
    echo "$(date -Iseconds),$metric,$value" >> "$LOG_FILE"
}

# System-Metriken sammeln
collect_system_metrics() {
    local cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    local mem=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    local disk=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    log_metric "cpu_usage" "$cpu"
    log_metric "memory_usage" "$mem"
    log_metric "disk_usage" "$disk"
}

# Container-Status prüfen
check_container_status() {
    if command -v docker >/dev/null 2>&1; then
        local running=$(docker ps --format "{{.Names}}" | wc -l)
        local total=$(docker ps -a --format "{{.Names}}" | wc -l)
        log_metric "docker_running" "$running"
        log_metric "docker_total" "$total"
    fi
    
    if command -v podman >/dev/null 2>&1; then
        local running=$(podman ps --format "{{.Names}}" | wc -l)
        local total=$(podman ps -a --format "{{.Names}}" | wc -l)
        log_metric "podman_running" "$running"
        log_metric "podman_total" "$total"
    fi
}

# Ansible-Performance prüfen
check_ansible_performance() {
    if [ -f "$ANALYTICS_DIR/performance.csv" ]; then
        local last_run=$(tail -1 "$ANALYTICS_DIR/performance.csv" | cut -d',' -f1)
        local last_duration=$(tail -1 "$ANALYTICS_DIR/performance.csv" | cut -d',' -f3)
        log_metric "last_playbook_duration" "$last_duration"
    fi
}

# Hauptfunktion
main() {
    mkdir -p "$ANALYTICS_DIR"
    
    echo "🔍 Sammle Performance-Metriken..."
    collect_system_metrics
    check_container_status
    check_ansible_performance
    
    echo "📊 Metriken gespeichert in: $LOG_FILE"
}

# Cron-Job-Setup
setup_cron() {
    echo "⏰ Performance-Monitoring als Cron-Job einrichten?"
    read -p "Alle 5 Minuten Metriken sammeln? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Cron-Job hinzufügen
        (crontab -l 2>/dev/null; echo "*/5 * * * * $0 >/dev/null 2>&1") | crontab -
        echo "✅ Cron-Job eingerichtet"
    fi
}

case "${1:-}" in
    --cron) main ;;
    --setup-cron) setup_cron ;;
    *) 
        main
        setup_cron
        ;;
esac
EOF
    
    chmod +x "$monitoring_dir/scripts/ansible-perf-monitor.sh"
    
    log_success "Performance-Monitoring Setup erstellt: $monitoring_dir"
    echo "  • Callback-Plugin: callbacks/performance_monitor.py"
    echo "  • Monitoring-Playbook: playbooks/system-monitoring.yml"
    echo "  • Monitoring-Script: scripts/ansible-perf-monitor.sh"
    echo
    echo "Verwendung:"
    echo "  export ANSIBLE_CALLBACK_PLUGINS=$monitoring_dir/callbacks"
    echo "  ansible-playbook -e callback_whitelist=performance_monitor playbook.yml"
}

export_analytics_report() {
    clear
    echo -e "${BRIGHT_BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_BLUE}║${NC}                   ${WHITE}📤 ANALYTICS REPORT EXPORT${NC}                      ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    local report_dir="$HOME/ansible-analytics-reports"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$report_dir/ansible-report-$timestamp.md"
    
    mkdir -p "$report_dir"
    
    echo
    log_info "Generiere umfassenden Analytics-Report..."
    
    # Markdown-Report erstellen
    cat > "$report_file" << EOF
# Ansible Performance Analytics Report
**Generiert am:** $(date)  
**Hostname:** $(hostname)  
**Benutzer:** $(whoami)  

## 📊 Executive Summary

EOF
    
    # Zusammenfassung generieren
    if [ -f "$PERFORMANCE_LOG" ] && [ $(wc -l < "$PERFORMANCE_LOG") -gt 1 ]; then
        local total_runs=$(tail -n +2 "$PERFORMANCE_LOG" | wc -l)
        local avg_duration=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$3} END {printf "%.2f", NR > 0 ? sum/NR : 0}')
        local success_rate=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{total++; if($6==0) success++} END {printf "%.1f", total > 0 ? (success*100)/total : 0}')
        local total_tasks=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$4} END {printf "%.0f", sum}')
        
        cat >> "$report_file" << EOF
- **Total Playbook Runs:** $total_runs
- **Average Duration:** ${avg_duration}s
- **Success Rate:** ${success_rate}%
- **Total Tasks Executed:** $total_tasks

## 📈 Performance Metrics

### Execution Time Trends
\`\`\`
$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{print $1 "," $3}' | tail -10)
\`\`\`

### Top Playbooks by Frequency
\`\`\`
$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{print $2}' | sort | uniq -c | sort -nr | head -5)
\`\`\`

### Performance Hotspots (>30s)
\`\`\`
$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '$3 > 30 {printf "%s: %.2fs\n", $2, $3}' | head -5)
\`\`\`

EOF
    else
        cat >> "$report_file" << EOF
- **Status:** Keine Performance-Daten verfügbar
- **Empfehlung:** Führe Playbooks aus um Metriken zu sammeln

EOF
    fi
    
    # System-Informationen hinzufügen
    cat >> "$report_file" << EOF
## 🖥️ System Information

- **OS:** $(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"')
- **Kernel:** $(uname -r)
- **Architecture:** $(uname -m)
- **CPU Cores:** $(nproc)
- **Memory:** $(free -h | awk '/^Mem:/{print $2}')
- **Ansible Version:** $(ansible --version 2>/dev/null | head -1 || echo "Not installed")

## 🐳 Container Status

EOF
    
    # Container-Status
    if command -v docker >/dev/null 2>&1; then
        local docker_total=$(docker ps -a --format "{{.Names}}" 2>/dev/null | wc -l)
        local docker_running=$(docker ps --format "{{.Names}}" 2>/dev/null | wc -l)
        cat >> "$report_file" << EOF
- **Docker Containers:** $docker_running running, $docker_total total
EOF
    fi
    
    if command -v podman >/dev/null 2>&1; then
        local podman_total=$(podman ps -a --format "{{.Names}}" 2>/dev/null | wc -l)
        local podman_running=$(podman ps --format "{{.Names}}" 2>/dev/null | wc -l)
        cat >> "$report_file" << EOF
- **Podman Containers:** $podman_running running, $podman_total total
EOF
    fi
    
    # Health-Daten hinzufügen
    cat >> "$report_file" << EOF

## 🩺 Health Status

EOF
    
    if [ -f "$HEALTH_LOG" ] && [ $(wc -l < "$HEALTH_LOG") -gt 1 ]; then
        cat >> "$report_file" << EOF
### Recent Health Checks
\`\`\`
$(tail -5 "$HEALTH_LOG")
\`\`\`
EOF
    else
        cat >> "$report_file" << EOF
- **Status:** Keine Health-Daten verfügbar
EOF
    fi
    
    # Optimierungsempfehlungen
    cat >> "$report_file" << EOF

## 💡 Optimization Recommendations

### Performance Optimizations
1. **Parallel Execution:** Increase forks parameter for faster execution
2. **SSH Optimization:** Enable pipelining and connection multiplexing
3. **Fact Caching:** Implement memory-based fact caching
4. **Task Optimization:** Use tags for selective execution

### Infrastructure Recommendations
1. **Container Optimization:** Use persistent volumes for data
2. **Network Optimization:** Implement SSH bastion hosts for remote access
3. **Monitoring:** Set up continuous performance monitoring
4. **Automation:** Implement CI/CD pipelines for playbook testing

### Security Considerations
1. **SSH Keys:** Use key-based authentication
2. **Vault:** Encrypt sensitive data with Ansible Vault
3. **Access Control:** Implement role-based access control
4. **Auditing:** Enable comprehensive logging and auditing

## 📊 Raw Data

### Performance Log Sample
\`\`\`csv
$(head -1 "$PERFORMANCE_LOG" 2>/dev/null || echo "timestamp,playbook,duration,tasks,changed,failed,ok,skipped,host,container")
$(tail -5 "$PERFORMANCE_LOG" 2>/dev/null)
\`\`\`

---
*Report generated by Ansible Enhanced Installation Script v2.1*  
*For more information visit: https://docs.ansible.com/*
EOF
    
    # JSON-Export für maschinelle Verarbeitung
    local json_file="$report_dir/ansible-data-$timestamp.json"
    
    cat > "$json_file" << EOF
{
  "report_metadata": {
    "generated_at": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "ansible_version": "$(ansible --version 2>/dev/null | head -1 || echo 'not installed')"
  },
  "system_info": {
    "os": "$(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '"')",
    "kernel": "$(uname -r)",
    "architecture": "$(uname -m)",
    "cpu_cores": $(nproc),
    "memory_gb": "$(free -g | awk '/^Mem:/{print $2}')"
  },
EOF
    
    # Performance-Daten als JSON
    if [ -f "$PERFORMANCE_LOG" ] && [ $(wc -l < "$PERFORMANCE_LOG") -gt 1 ]; then
        echo '  "performance_data": [' >> "$json_file"
        tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{
            printf "    {\"timestamp\":\"%s\",\"playbook\":\"%s\",\"duration\":%s,\"tasks\":%s,\"changed\":%s,\"failed\":%s,\"ok\":%s,\"skipped\":%s,\"host\":\"%s\",\"container\":\"%s\"}", 
                   $1,$2,$3,$4,$5,$6,$7,$8,$9,$10
            if(NR < total_lines) printf ","
            printf "\n"
        }' total_lines=$(tail -n +2 "$PERFORMANCE_LOG" | wc -l) >> "$json_file"
        echo '  ]' >> "$json_file"
    else
        echo '  "performance_data": []' >> "$json_file"
    fi
    
    echo '}' >> "$json_file"
    
    # CSV-Export für Spreadsheet-Anwendungen
    if [ -f "$PERFORMANCE_LOG" ]; then
        cp "$PERFORMANCE_LOG" "$report_dir/performance-data-$timestamp.csv"
    fi
    
    if [ -f "$HEALTH_LOG" ]; then
        cp "$HEALTH_LOG" "$report_dir/health-data-$timestamp.csv"
    fi
    
    log_success "Analytics-Report exportiert!"
    echo
    echo "📁 Report-Dateien:"
    echo "  • Markdown-Report: $report_file"
    echo "  • JSON-Daten: $json_file"
    echo "  • CSV-Performance: $report_dir/performance-data-$timestamp.csv"
    echo "  • CSV-Health: $report_dir/health-data-$timestamp.csv"
    echo
    echo "📤 Export-Optionen:"
    echo "1) Report in Browser öffnen"
    echo "2) Report per E-Mail versenden"
    echo "3) Report in Cloud hochladen"
    echo "4) Zurück zum Analytics-Menü"
    
    read -p "Option wählen [1-4]: " export_choice
    
    case $export_choice in
        1) 
            if command -v firefox >/dev/null 2>&1; then
                firefox "$report_file" &
            elif command -v chromium >/dev/null 2>&1; then
                chromium "$report_file" &
            else
                log_info "Bitte öffne manuell: $report_file"
            fi
            ;;
        2)
            read -p "E-Mail-Adresse: " email
            if command -v mail >/dev/null 2>&1 && [ -n "$email" ]; then
                mail -s "Ansible Analytics Report $(date +%Y-%m-%d)" "$email" < "$report_file"
                log_success "Report per E-Mail versendet"
            else
                log_warning "Mail-Befehl nicht verfügbar oder keine E-Mail angegeben"
            fi
            ;;
        3)
            log_info "Cloud-Upload wird in einem kommenden Update verfügbar sein"
            ;;
        4) ;;
    esac
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
    show_performance_analytics
}

# Alle bestehenden Funktionen beibehalten und erweiterte main() Funktion

# Banner anzeigen
show_banner() {
    clear
    echo
    echo -e "${BRIGHT_BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_BLUE}║${NC}                        ${WHITE}🚀 ANSIBLE INSTALLER v2.1 🚀${NC}                       ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}║${NC}                         ${CYAN}ENHANCED EDITION${NC}                            ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BRIGHT_BLUE}║${NC} ${BRIGHT_GREEN}🆕 NEU:${NC} Health Dashboard + Performance Analytics              ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}║${NC} ${BRIGHT_GREEN}🌐 NEU:${NC} Remote Container Management                            ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}║${NC} ${BRIGHT_GREEN}🎮 NEU:${NC} Interactive Playbook Builder                          ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}║${NC} ${BRIGHT_GREEN}📊 NEU:${NC} Erweiterte Monitoring & Analytics                     ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    
    # Status-Cards mit erweiterten Informationen
    local current_container=$(get_current_container_name)
    
    echo -e "${CYAN}┌─ 📅 STATUS & ANALYTICS ────────────┬─ 🐳 CONTAINER ENGINES ─────────┐${NC}"
    printf "${CYAN}│${NC} %-34s ${CYAN}│${NC} %-30s ${CYAN}│${NC}\n" \
           "📆 KW: $(date +%V) / Jahr: $(date +%Y)" \
           "$(check_docker_status)"
    printf "${CYAN}│${NC} %-34s ${CYAN}│${NC} %-30s ${CYAN}│${NC}\n" \
           "🏷️  Container: $current_container" \
           "$(check_podman_status)"
    printf "${CYAN}│${NC} %-34s ${CYAN}│${NC} %-30s ${CYAN}│${NC}\n" \
           "📊 Analytics: $(check_analytics_status)" \
           "🩺 Health: $(check_health_status)"
    echo -e "${CYAN}└────────────────────────────────────┴─────────────────────────────────┘${NC}"
    
    # Container-Status-Card
    show_container_status_card "$current_container"
}

check_analytics_status() {
    if [ -f "$PERFORMANCE_LOG" ] && [ $(wc -l < "$PERFORMANCE_LOG") -gt 1 ]; then
        local runs=$(tail -n +2 "$PERFORMANCE_LOG" | wc -l)
        echo "${GREEN}✅ $runs Runs${NC}"
    else
        echo "${YELLOW}⚠️  Keine Daten${NC}"
    fi
}

check_health_status() {
    if [ -f "$HEALTH_LOG" ] && [ $(wc -l < "$HEALTH_LOG") -gt 1 ]; then
        echo "${GREEN}✅ Aktiv${NC}"
    else
        echo "${GRAY}❓ Inaktiv${NC}"
    fi
}

# Prüfen ob Script als root ausgeführt wird
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "Dieses Script sollte NICHT als root ausgeführt werden!"
        log_info "Führe es als normaler User aus: ./ansible.sh"
        exit 1
    fi
}

# Prüfen ob es Manjaro ist
check_manjaro() {
    if ! grep -q "Manjaro" /etc/os-release; then
        log_warning "Dieses Script ist für Manjaro optimiert."
        read -p "Trotzdem fortfahren? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Performance-Historie anzeigen
show_performance_history() {
    clear
    echo -e "${BRIGHT_PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_PURPLE}║${NC}                    ${WHITE}📈 PERFORMANCE HISTORIE${NC}                         ${BRIGHT_PURPLE}║${NC}"
    echo -e "${BRIGHT_PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    if [ ! -f "$PERFORMANCE_LOG" ] || [ $(wc -l < "$PERFORMANCE_LOG") -le 1 ]; then
        echo
        echo -e "${YELLOW}Keine Performance-Historie verfügbar${NC}"
        read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
        show_performance_analytics
        return
    fi
    
    echo
    echo -e "${PURPLE}=== VOLLSTÄNDIGE AUSFÜHRUNGSHISTORIE ===${NC}"
    echo
    
    # Header
    printf "%-19s %-25s %8s %5s %3s %3s %3s %-12s\n" \
           "ZEITSTEMPEL" "PLAYBOOK" "DAUER" "TASKS" "CHG" "ERR" "OK" "HOST"
    echo "$(printf '─%.0s' {1..80})"
    
    # Alle Einträge anzeigen
    tail -n +2 "$PERFORMANCE_LOG" | while IFS=',' read -r timestamp playbook duration tasks changed failed ok skipped host container; do
        local status_icon="✅"
        if [ "$failed" -gt 0 ]; then
            status_icon="❌"
        elif [ "$changed" -eq 0 ]; then
            status_icon="⚡"
        fi
        
        local short_time=$(echo "$timestamp" | cut -d'T' -f2 | cut -d'+' -f1)
        local short_playbook=$(basename "$playbook" .yml | cut -c1-23)
        local short_host=$(echo "$host" | cut -c1-10)
        
        printf "%s %-25s %7.2fs %5s %3s %3s %3s %-12s %s\n" \
               "$short_time" "$short_playbook" "$duration" "$tasks" \
               "$changed" "$failed" "$ok" "$short_host" "$status_icon"
    done | tail -20
    
    echo
    echo -e "${PURPLE}=== STATISTIKEN ===${NC}"
    
    # Detaillierte Statistiken
    local total_duration=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$3} END {printf "%.2f", sum}')
    local fastest=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' 'NR==1{min=$3} {if($3<min) min=$3} END {printf "%.2f", min}')
    local slowest=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{if($3>max) max=$3} END {printf "%.2f", max}')
    local median=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{print $3}' | sort -n | awk '{a[NR]=$1} END {print (NR%2==1) ? a[(NR+1)/2] : (a[NR/2]+a[NR/2+1])/2}')
    
    echo "Gesamt-Laufzeit: ${total_duration}s"
    echo "Schnellste Ausführung: ${fastest}s"
    echo "Langsamste Ausführung: ${slowest}s"
    echo "Median-Laufzeit: ${median}s"
    
    echo
    echo "Aktionen:"
    echo "1) Detailanalyse für spezifisches Playbook"
    echo "2) Performance-Trends exportieren"
    echo "3) Zurück zum Analytics-Menü"
    
    read -p "Aktion wählen [1-3]: " history_action
    
    case $history_action in
        1)
            echo
            echo "Verfügbare Playbooks:"
            tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{print $2}' | sort -u | nl
            read -p "Playbook-Nummer auswählen: " pb_num
            
            local selected_playbook=$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{print $2}' | sort -u | sed -n "${pb_num}p")
            if [ -n "$selected_playbook" ]; then
                echo
                echo "=== ANALYSE: $(basename "$selected_playbook" .yml) ==="
                tail -n +2 "$PERFORMANCE_LOG" | awk -F',' -v pb="$selected_playbook" '$2==pb {
                    sum+=$3; count++; if($3>max) max=$3; if(min=="" || $3<min) min=$3
                } END {
                    printf "Ausführungen: %d\n", count
                    printf "Durchschnitt: %.2fs\n", sum/count
                    printf "Min/Max: %.2fs / %.2fs\n", min, max
                }'
            fi
            ;;
        2)
            local export_file="$HOME/ansible-performance-trends-$(date +%Y%m%d_%H%M%S).csv"
            cp "$PERFORMANCE_LOG" "$export_file"
            log_success "Performance-Daten exportiert: $export_file"
            ;;
        3) ;;
    esac
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
    show_performance_analytics
}

manage_analytics_data() {
    clear
    echo -e "${BRIGHT_YELLOW}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_YELLOW}║${NC}                   ${WHITE}🧹 ANALYTICS-DATEN VERWALTEN${NC}                     ${BRIGHT_YELLOW}║${NC}"
    echo -e "${BRIGHT_YELLOW}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    echo -e "${YELLOW}Aktuelle Analytics-Daten:${NC}"
    echo
    
    # Dateigröße und Anzahl Einträge anzeigen
    if [ -f "$PERFORMANCE_LOG" ]; then
        local perf_size=$(du -h "$PERFORMANCE_LOG" | cut -f1)
        local perf_lines=$(($(wc -l < "$PERFORMANCE_LOG") - 1))
        echo "📊 Performance-Log: $perf_size, $perf_lines Einträge"
    else
        echo "📊 Performance-Log: Nicht vorhanden"
    fi
    
    if [ -f "$HEALTH_LOG" ]; then
        local health_size=$(du -h "$HEALTH_LOG" | cut -f1)
        local health_lines=$(($(wc -l < "$HEALTH_LOG") - 1))
        echo "🩺 Health-Log: $health_size, $health_lines Einträge"
    else
        echo "🩺 Health-Log: Nicht vorhanden"
    fi
    
    local analytics_total_size=$(du -sh "$ANALYTICS_DIR" 2>/dev/null | cut -f1 || echo "0B")
    echo "📁 Gesamt-Verzeichnis: $analytics_total_size"
    
    echo
    echo -e "${CYAN}Verwaltungsoptionen:${NC}"
    echo "1) 🗑️  Analytics-Daten löschen (komplett)"
    echo "2) 🧹 Alte Einträge bereinigen (>30 Tage)"
    echo "3) 📤 Daten exportieren vor Bereinigung"
    echo "4) 📋 Detaillierte Datei-Analyse"
    echo "5) 🔄 Analytics-System zurücksetzen"
    echo "6) 📊 Statistiken neu berechnen"
    echo "7) 🔙 Zurück zum Analytics-Menü"
    
    echo
    read -p "Option wählen [1-7]: " manage_choice
    
    case $manage_choice in
        1)
            echo
            log_warning "ACHTUNG: Alle Analytics-Daten werden gelöscht!"
            read -p "Wirklich ALLE Analytics-Daten löschen? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$ANALYTICS_DIR"
                log_success "Analytics-Daten gelöscht"
                init_analytics
            fi
            ;;
        2)
            echo
            log_info "Bereinige Einträge älter als 30 Tage..."
            local cutoff_date=$(date -d '30 days ago' '+%Y-%m-%d')
            
            if [ -f "$PERFORMANCE_LOG" ]; then
                local before_lines=$(wc -l < "$PERFORMANCE_LOG")
                head -1 "$PERFORMANCE_LOG" > "${PERFORMANCE_LOG}.tmp"
                awk -F',' -v cutoff="$cutoff_date" '$1 >= cutoff' "$PERFORMANCE_LOG" >> "${PERFORMANCE_LOG}.tmp"
                mv "${PERFORMANCE_LOG}.tmp" "$PERFORMANCE_LOG"
                local after_lines=$(wc -l < "$PERFORMANCE_LOG")
                log_success "Performance-Log: $((before_lines - after_lines)) alte Einträge entfernt"
            fi
            
            if [ -f "$HEALTH_LOG" ]; then
                local before_lines=$(wc -l < "$HEALTH_LOG")
                head -1 "$HEALTH_LOG" > "${HEALTH_LOG}.tmp"
                awk -F',' -v cutoff="$cutoff_date" '$1 >= cutoff' "$HEALTH_LOG" >> "${HEALTH_LOG}.tmp"
                mv "${HEALTH_LOG}.tmp" "$HEALTH_LOG"
                local after_lines=$(wc -l < "$HEALTH_LOG")
                log_success "Health-Log: $((before_lines - after_lines)) alte Einträge entfernt"
            fi
            ;;
        3)
            echo
            log_info "Exportiere Analytics-Daten vor Bereinigung..."
            export_analytics_report
            return
            ;;
        4)
            echo
            echo -e "${BLUE}=== DETAILLIERTE DATEI-ANALYSE ===${NC}"
            
            for log_file in "$PERFORMANCE_LOG" "$HEALTH_LOG"; do
                if [ -f "$log_file" ]; then
                    local filename=$(basename "$log_file")
                    echo
                    echo "📄 $filename:"
                    echo "   Größe: $(du -h "$log_file" | cut -f1)"
                    echo "   Zeilen: $(wc -l < "$log_file")"
                    echo "   Erstellt: $(stat -c %y "$log_file" | cut -d' ' -f1)"
                    echo "   Geändert: $(stat -c %z "$log_file" | cut -d' ' -f1)"
                    
                    if [ "$filename" = "performance.csv" ] && [ $(wc -l < "$log_file") -gt 1 ]; then
                        echo "   Erster Eintrag: $(tail -n +2 "$log_file" | head -1 | cut -d',' -f1)"
                        echo "   Letzter Eintrag: $(tail -1 "$log_file" | cut -d',' -f1)"
                        echo "   Eindeutige Playbooks: $(tail -n +2 "$log_file" | awk -F',' '{print $2}' | sort -u | wc -l)"
                    fi
                fi
            done
            ;;
        5)
            echo
            log_warning "Analytics-System wird zurückgesetzt (Daten bleiben erhalten)"
            read -p "Analytics-System neu initialisieren? (Y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                # Backup erstellen
                local backup_dir="$ANALYTICS_DIR/backup-$(date +%s)"
                mkdir -p "$backup_dir"
                cp "$ANALYTICS_DIR"/*.csv "$backup_dir" 2>/dev/null || true
                cp "$ANALYTICS_DIR"/*.conf "$backup_dir" 2>/dev/null || true
                
                # System neu initialisieren
                init_analytics
                
                log_success "Analytics-System zurückgesetzt"
                log_info "Backup erstellt in: $backup_dir"
            fi
            ;;
        6)
            echo
            log_info "Berechne Statistiken neu..."
            
            if [ -f "$PERFORMANCE_LOG" ] && [ $(wc -l < "$PERFORMANCE_LOG") -gt 1 ]; then
                local stats_file="$ANALYTICS_DIR/computed-stats.txt"
                
                cat > "$stats_file" << EOF
=== ANSIBLE PERFORMANCE STATISTIKEN ===
Generiert: $(date)

Gesamt-Ausführungen: $(tail -n +2 "$PERFORMANCE_LOG" | wc -l)
Durchschnittliche Dauer: $(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$3} END {printf "%.2fs", NR > 0 ? sum/NR : 0}')
Gesamt-Laufzeit: $(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{sum+=$3} END {printf "%.2fs", sum}')
Erfolgsrate: $(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{total++; if($6==0) success++} END {printf "%.1f%%", total > 0 ? (success*100)/total : 0}')

Top-Playbooks (nach Häufigkeit):
$(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{print $2}' | sort | uniq -c | sort -nr | head -5)

Performance-Extremwerte:
Schnellste Ausführung: $(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' 'NR==1{min=$3} {if($3<min) min=$3} END {printf "%.2fs", min}')
Langsamste Ausführung: $(tail -n +2 "$PERFORMANCE_LOG" | awk -F',' '{if($3>max) max=$3} END {printf "%.2fs", max}')
EOF
                
                log_success "Statistiken neu berechnet: $stats_file"
                echo
                cat "$stats_file"
            else
                log_warning "Keine Performance-Daten für Statistiken verfügbar"
            fi
            ;;
        7) ;;
    esac
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
    show_performance_analytics
}

# Installation-Optionen (bestehende Funktionen beibehalten)
do_minimal_install() {
    update_system
    install_package "ansible"
    install_package "python"
    install_package "openssh"
    log_success "Minimale Installation abgeschlossen"
}

do_base_install() {
    update_system
    install_base_packages
    setup_ssh_keys
    setup_ansible_config
    create_project_template
    test_installation
}

do_full_install() {
    update_system
    install_base_packages
    install_docker
    install_vscode
    install_additional_tools
    setup_ssh_keys
    setup_ansible_config
    create_project_template
    setup_docker_test
    test_installation
}

# Hauptfunktion mit erweiterten Features
main() {
    # Analytics initialisieren
    init_analytics
    
    show_banner
    check_root
    check_manjaro
    
    # Cleanup bei Exit
    trap cleanup EXIT
    
    while true; do
        show_enhanced_menu
        read -p "$(echo -e "${WHITE}Wähle eine Option [1-15]: ${BRIGHT_CYAN}")" choice
        echo -e "${NC}"
        
        # Eingabe validieren
        if ! [[ "$choice" =~ ^[1-9]$|^1[0-5]$ ]]; then
            echo
            echo -e "${RED}┌─ ❌ UNGÜLTIGE EINGABE ─────────────────────────────────────────────┐${NC}"
            echo -e "${RED}│${NC} Bitte wähle eine Zahl zwischen 1 und 15.                      ${RED}│${NC}"
            echo -e "${RED}└─────────────────────────────────────────────────────────────────────┘${NC}"
            sleep 2
            continue
        fi
        
        case $choice in
            1)
                clear
                print_header "🔧 BASIS-INSTALLATION" "$BRIGHT_YELLOW"
                do_base_install
                break
                ;;
            2)
                clear
                print_header "⚡ VOLLSTÄNDIGE INSTALLATION" "$BRIGHT_GREEN"
                do_full_install
                break
                ;;
            3)
                clear
                print_header "📦 MINIMALE INSTALLATION" "$BRIGHT_BLUE"
                do_minimal_install
                break
                ;;
            4)
                clear
                print_header "🎛️  CUSTOM INSTALLATION" "$BRIGHT_PURPLE"
                do_custom_install
                break
                ;;
            5)
                clear
                print_header "🧪 TESTUMGEBUNG EINRICHTEN" "$CYAN"
                setup_docker_test
                break
                ;;
            6)
                clear
                print_header "🔒 DOCKER-CONTAINER" "$BLUE"
                run_in_docker_container
                ;;
            7)
                clear
                print_header "🐋 DOCKER AUTO-INSTALLATION" "$BRIGHT_BLUE"
                create_weekly_container_auto
                break
                ;;
            8)
                clear
                print_header "🐳 PODMAN AUTO-INSTALLATION (ROOTLESS)" "$BRIGHT_PURPLE"
                create_podman_container_auto
                break
                ;;
            9)
                manage_containers
                ;;
            10)
                show_progress_demo
                ;;
            11)
                show_health_dashboard
                ;;
            12)
                show_remote_management
                ;;
            13)
                show_playbook_builder
                ;;
            14)
                show_performance_analytics
                ;;
            15)
                echo
                echo -e "${YELLOW}┌─ 👋 SCRIPT BEENDEN ────────────────────────────────────────────────┐${NC}"
                echo -e "${YELLOW}│${NC} Möchtest du vor dem Beenden aufräumen?                         ${YELLOW}│${NC}"
                echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────────┘${NC}"
                
                read -p "$(echo -e "${WHITE}Container aufräumen? (y/N): ${NC}")" -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    cleanup_containers
                fi
                
                echo
                echo -e "${GREEN}┌─ ✅ ENHANCED ANSIBLE INSTALLER ───────────────────────────────────┐${NC}"
                echo -e "${GREEN}│${NC} Vielen Dank für die Nutzung der Enhanced Edition!             ${GREEN}│${NC}"
                echo -e "${GREEN}│${NC} Neue Features: Health Dashboard, Remote Management,           ${GREEN}│${NC}"
                echo -e "${GREEN}│${NC} Playbook Builder & Performance Analytics                       ${GREEN}│${NC}"
                echo -e "${GREEN}│${NC} Dokumentation: https://docs.ansible.com/                      ${GREEN}│${NC}"
                echo -e "${GREEN}└─────────────────────────────────────────────────────────────────────┘${NC}"
                
                exit 0
                ;;
        esac
    done
    
    echo
    log_success "Enhanced Installation abgeschlossen!"
    echo
    log_info "🚀 Nächste Schritte:"
    echo "1. Neue Features testen: Health Dashboard (Option 11)"
    echo "2. Remote-Hosts verwalten: Remote Management (Option 12)"  
    echo "3. Playbooks erstellen: Interactive Builder (Option 13)"
    echo "4. Performance überwachen: Analytics (Option 14)"
    echo "5. cd ~/ansible-projekte/webserver-beispiel"
    echo "6. ansible-playbook playbooks/test.yml"
    echo
    log_info "🩺 Erweiterte Features:"
    echo "• Health Dashboard: System & Container Monitoring"
    echo "• Remote Management: Container auf anderen Hosts"
    echo "• Playbook Builder: Interaktive Erstellung"
    echo "• Performance Analytics: Metriken & Optimierung"
    echo
    log_success "Enhanced Ansible Installer v2.1 - Viel Erfolg!"
}

# Script starten
main "$@"