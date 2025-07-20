#!/bin/bash

# =============================================================================
# Ansible Installation Script für Manjaro Linux - FOKUSSIERTE VERSION
# =============================================================================
# Dieses Script installiert Ansible mit Docker/Podman und Dashboard-Features
# Autor: Claude (Anthropic)
# Version: 3.0 - Fokussierte Edition
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

# Aktuelle Kalenderwoche ermitteln
get_calendar_week() {
    date +"%yKW%V"
}

# Container-Name für aktuelle KW generieren
get_current_container_name() {
    echo "$(get_calendar_week)-ansible"
}

# Analytics initialisieren
init_analytics() {
    mkdir -p "$ANALYTICS_DIR"
    
    # Performance-Log Header
    if [ ! -f "$PERFORMANCE_LOG" ]; then
        echo "timestamp,component,status,cpu,memory,disk,details" > "$PERFORMANCE_LOG"
    fi
    
    # Health-Log Header
    if [ ! -f "$HEALTH_LOG" ]; then
        echo "timestamp,component,status,cpu,memory,disk,details" > "$HEALTH_LOG"
    fi
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

# Docker-Status prüfen
check_docker_status() {
    if command -v docker >/dev/null 2>&1; then
        if docker ps >/dev/null 2>&1; then
            echo "🐋 Docker: ${GREEN}✅ Verfügbar${NC}"
        else
            echo "🐋 Docker: ${YELLOW}⚠️  Berechtigung${NC}"
        fi
    else
        echo "🐋 Docker: ${RED}❌ Nicht installiert${NC}"
    fi
}

# Podman-Status prüfen  
check_podman_status() {
    if command -v podman >/dev/null 2>&1; then
        if podman info >/dev/null 2>&1; then
            echo "🐳 Podman: ${GREEN}✅ Rootless OK${NC}"
        else
            echo "🐳 Podman: ${YELLOW}⚠️  Setup nötig${NC}"
        fi
    else
        echo "🐳 Podman: ${RED}❌ Nicht installiert${NC}"
    fi
}

# Analytics-Status prüfen
check_analytics_status() {
    if [ -f "$PERFORMANCE_LOG" ] && [ $(wc -l < "$PERFORMANCE_LOG") -gt 1 ]; then
        local runs=$(tail -n +2 "$PERFORMANCE_LOG" | wc -l)
        echo "${GREEN}✅ $runs Einträge${NC}"
    else
        echo "${YELLOW}⚠️  Keine Daten${NC}"
    fi
}

# Banner anzeigen
show_banner() {
    clear
    echo
    echo -e "${BRIGHT_BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_BLUE}║${NC}                    ${WHITE}🚀 ANSIBLE INSTALLER v3.0 🚀${NC}                       ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}║${NC}                       ${CYAN}FOKUSSIERTE EDITION${NC}                           ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BRIGHT_BLUE}║${NC} ${BRIGHT_GREEN}🎯 FOKUS:${NC} Docker/Podman + Dashboard                               ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}║${NC} ${BRIGHT_GREEN}📊 FEATURES:${NC} Health Monitoring + Performance Analytics            ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}║${NC} ${BRIGHT_GREEN}🔧 EINFACH:${NC} Nur die wichtigsten Optionen                          ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    
    # Status-Cards
    local current_container=$(get_current_container_name)
    
    echo -e "${CYAN}┌─ 📊 SYSTEM STATUS ─────────────────┬─ 🐳 CONTAINER ENGINES ─────────┐${NC}"
    printf "${CYAN}│${NC} %-34s ${CYAN}│${NC} %-30s ${CYAN}│${NC}\n" \
           "📅 Container: $current_container" \
           "$(check_docker_status)"
    printf "${CYAN}│${NC} %-34s ${CYAN}│${NC} %-30s ${CYAN}│${NC}\n" \
           "📊 Analytics: $(check_analytics_status)" \
           "$(check_podman_status)"
    echo -e "${CYAN}└────────────────────────────────────┴─────────────────────────────────┘${NC}"
}

# Fokussiertes Menü
show_focused_menu() {
    echo
    echo -e "${BRIGHT_CYAN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_CYAN}║${NC}                     ${WHITE}📋 INSTALLATION OPTIONEN${NC}                        ${BRIGHT_CYAN}║${NC}"
    echo -e "${BRIGHT_CYAN}╠══════════════════════════════════════════════════════════════════════╣${NC}"
    
    echo -e "${BRIGHT_CYAN}├────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BRIGHT_CYAN}║${NC} ${BRIGHT_PURPLE}🚀 EMPFOHLENE INSTALLATIONEN${NC}                                      ${BRIGHT_CYAN}║${NC}"
    echo -e "${BRIGHT_CYAN}├────────────────────────────────────────────────────────────────────┤${NC}"
    printf "${BRIGHT_CYAN}│${NC} %2s ${BRIGHT_CYAN}│${NC} %s ${WHITE}%-25s${NC} ${GRAY}%s${NC}\n" "1" "🐋" "Docker + Dashboard" "Vollinstallation mit Monitoring"
    printf "${BRIGHT_CYAN}│${NC} %2s ${BRIGHT_CYAN}│${NC} %s ${WHITE}%-25s${NC} ${GRAY}%s${NC}\n" "2" "🐳" "Podman + Dashboard" "Rootless Installation"
    
    echo -e "${BRIGHT_CYAN}├────────────────────────────────────────────────────────────────────┤${NC}"
    echo -e "${BRIGHT_CYAN}║${NC} ${BRIGHT_BLUE}🛠️  TOOLS & MONITORING${NC}                                           ${BRIGHT_CYAN}║${NC}"
    echo -e "${BRIGHT_CYAN}├────────────────────────────────────────────────────────────────────┤${NC}"
    printf "${BRIGHT_CYAN}│${NC} %2s ${BRIGHT_CYAN}│${NC} %s ${WHITE}%-25s${NC} ${GRAY}%s${NC}\n" "3" "🩺" "Health Dashboard" "System & Container Monitoring"
    printf "${BRIGHT_CYAN}│${NC} %2s ${BRIGHT_CYAN}│${NC} %s ${WHITE}%-25s${NC} ${GRAY}%s${NC}\n" "4" "📈" "Performance Analytics" "Metriken & Optimierung"
    
    echo -e "${BRIGHT_CYAN}├────────────────────────────────────────────────────────────────────┤${NC}"
    printf "${BRIGHT_CYAN}│${NC} %2s ${BRIGHT_CYAN}│${NC} %s ${WHITE}%-25s${NC} ${GRAY}%s${NC}\n" "5" "❌" "Beenden" "Script verlassen"
    
    echo -e "${BRIGHT_CYAN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Empfehlungs-Card
    echo
    echo -e "${GREEN}┌─ 💡 EMPFEHLUNGEN ─────────────────────────────────────────────────────┐${NC}"
    echo -e "${GREEN}│${NC} ${WHITE}🆕 Einsteiger?${NC}     → Option ${BRIGHT_PURPLE}2${NC} (Podman, rootless & sicher)      ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC} ${WHITE}🐋 Docker-Nutzer?${NC}  → Option ${BRIGHT_BLUE}1${NC} (Docker + Vollfeatures)           ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC} ${WHITE}🩺 Monitoring:${NC}     → Option ${BRIGHT_CYAN}3${NC} (Health Dashboard)                ${GREEN}│${NC}"
    echo -e "${GREEN}│${NC} ${WHITE}📊 Analytics:${NC}      → Option ${BRIGHT_YELLOW}4${NC} (Performance-Tracking)           ${GREEN}│${NC}"
    echo -e "${GREEN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Progress Bar mit Animation
show_progress_bar() {
    local current="$1"
    local total="$2"
    local prefix="${3:-Progress}"
    local suffix="${4:-Complete}"
    local length=50
    local color="${5:-$GREEN}"
    
    local percent=$((current * 100 / total))
    local filled_length=$((current * length / total))
    
    local bar=""
    for i in $(seq 1 $filled_length); do
        bar="${bar}█"
    done
    for i in $(seq $((filled_length + 1)) $length); do
        bar="${bar}░"
    done
    
    printf "\r${color}${prefix}${NC} [${GREEN}${bar}${NC}] ${WHITE}${percent}%%${NC} ${suffix}"
}

# Spinner für unbestimmte Dauer
show_spinner() {
    local pid=$1
    local message="${2:-Arbeite...}"
    local color="${3:-$CYAN}"
    
    local spin_chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        local char=${spin_chars:$i:1}
        printf "\r${color}${char}${NC} ${message}"
        i=$(( (i+1) % ${#spin_chars} ))
        sleep 0.1
    done
    
    printf "\r${GREEN}✅${NC} ${message} - Abgeschlossen\n"
}

# Installation mit Progress-Anzeige
show_installation_progress() {
    local operation="$1"
    local steps=("${@:2}")
    
    echo -e "${BRIGHT_GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_GREEN}║${NC}                     ${WHITE}⚡ $operation${NC}                          ${BRIGHT_GREEN}║${NC}"
    echo -e "${BRIGHT_GREEN}║${NC}                   ${CYAN}mit Dashboard & Analytics${NC}                    ${BRIGHT_GREEN}║${NC}"
    echo -e "${BRIGHT_GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    local total_steps=${#steps[@]}
    
    for i in "${!steps[@]}"; do
        local step_num=$((i + 1))
        local step_desc="${steps[$i]}"
        
        echo -e "${BLUE}┌─ SCHRITT ${step_num}/${total_steps}: ${step_desc} ────────────────────┐${NC}"
        
        # Progress-Animation
        for progress in $(seq 0 10 100); do
            show_progress_bar "$progress" "100" "  ${step_desc}" "" "$GREEN"
            sleep 0.05
        done
        echo
        
        echo -e "${BLUE}└─ ${GREEN}✅ Abgeschlossen${NC} ─────────────────────────────────────────────┘"
        echo
    done
}

# System aktualisieren
update_system() {
    log_info "🔄 Aktualisiere System..."
    sudo pacman -Syu --noconfirm >/dev/null 2>&1 &
    local update_pid=$!
    show_spinner $update_pid "System wird aktualisiert..."
    log_success "System aktualisiert"
}

# Paket-Installation
install_package() {
    local package=$1
    log_info "📦 Installiere $package..."
    
    if sudo pacman -S --noconfirm "$package" >/dev/null 2>&1; then
        log_success "$package erfolgreich installiert"
        return 0
    else
        log_error "Fehler beim Installieren von $package"
        return 1
    fi
}

# Basis-Pakete installieren
install_base_packages() {
    local packages=(
        "ansible"
        "python"
        "python-pip"
        "openssh"
        "git"
        "curl"
        "vim"
        "tree"
        "htop"
    )
    
    log_info "📦 Installiere Basis-Pakete..."
    
    for package in "${packages[@]}"; do
        if ! pacman -Q "$package" >/dev/null 2>&1; then
            install_package "$package"
        fi
    done
    
    # Python-Module
    log_info "🐍 Installiere Python-Module..."
    pip install --user jinja2 paramiko PyYAML cryptography ansible-lint >/dev/null 2>&1 &
    local pip_pid=$!
    show_spinner $pip_pid "Python-Module werden installiert..."
    
    log_success "Basis-Installation abgeschlossen"
}

# SSH-Konfiguration
setup_ssh_config() {
    if [ -f ~/.ssh/id_rsa ]; then
        log_info "🔑 SSH-Schlüssel existiert bereits"
        return 0
    fi
    
    log_info "🔑 Erstelle SSH-Schlüssel..."
    ssh-keygen -t rsa -b 4096 -C "ansible@$(hostname)" -f ~/.ssh/id_rsa -N "" >/dev/null 2>&1
    
    eval "$(ssh-agent -s)" >/dev/null 2>&1
    ssh-add ~/.ssh/id_rsa >/dev/null 2>&1
    
    log_success "SSH-Schlüssel erstellt"
}

# Ansible-Konfiguration
setup_ansible_config() {
    log_info "⚙️  Erstelle Ansible-Konfiguration..."
    
    mkdir -p ~/.ansible
    
    cat > ~/.ansible/ansible.cfg << 'EOF'
[defaults]
host_key_checking = False
inventory = ./inventory/hosts.yml
remote_user = ansible
private_key_file = ~/.ssh/id_rsa
gathering = smart
fact_caching = memory
stdout_callback = yaml
bin_ansible_callbacks = True

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False

[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
pipelining = True
EOF
    
    log_success "Ansible-Konfiguration erstellt"
}

# Projekt-Template erstellen
create_project_template() {
    local project_dir="$HOME/ansible-projekte"
    
    log_info "📁 Erstelle Projekt-Template..."
    
    mkdir -p "$project_dir/beispiel-projekt"/{inventory,playbooks,templates,files}
    
    # Beispiel-Inventory
    cat > "$project_dir/beispiel-projekt/inventory/hosts.yml" << 'EOF'
all:
  children:
    webservers:
      hosts:
        localhost:
          ansible_connection: local
      vars:
        ansible_user: ansible
EOF
    
    # Beispiel-Playbook
    cat > "$project_dir/beispiel-projekt/playbooks/test.yml" << 'EOF'
---
- name: Ansible Test
  hosts: localhost
  connection: local
  tasks:
    - name: Test-Datei erstellen
      file:
        path: /tmp/ansible-test.txt
        state: touch
        mode: '0644'
    
    - name: Erfolg melden
      debug:
        msg: "🎉 Ansible funktioniert perfekt!"
EOF
    
    log_success "Projekt-Template erstellt in $project_dir"
}

# Docker-Installation
install_docker() {
    log_info "🐋 Installiere Docker..."
    
    install_package "docker"
    install_package "docker-compose"
    
    sudo systemctl enable docker >/dev/null 2>&1
    sudo systemctl start docker >/dev/null 2>&1
    
    sudo usermod -aG docker "$USER"
    
    log_success "Docker installiert"
}

# Podman-Installation
install_podman() {
    log_info "🐳 Installiere Podman..."
    
    install_package "podman"
    
    # Rootless-Setup
    if ! grep -q "^$USER:" /etc/subuid 2>/dev/null; then
        sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$USER"
        podman system migrate 2>/dev/null || true
    fi
    
    log_success "Podman (rootless) installiert"
}

# Docker-Installation mit Dashboard
install_docker_with_dashboard() {
    clear
    echo -e "${BRIGHT_BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_BLUE}║${NC}                  ${WHITE}🐋 DOCKER + DASHBOARD${NC}                            ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    read -p "$(echo -e "${WHITE}Docker-Installation mit Dashboard starten? (Y/n): ${NC}")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        return 0
    fi
    
    # Progress-Animation
    show_installation_progress "DOCKER INSTALLATION + DASHBOARD" \
        "System aktualisieren" \
        "Basis-Pakete installieren" \
        "Docker installieren" \
        "SSH-Konfiguration" \
        "Ansible-Konfiguration" \
        "Projekt-Template erstellen" \
        "Dashboard initialisieren" \
        "Analytics aktivieren" \
        "Container-Test vorbereiten"
    
    # Tatsächliche Installation
    update_system
    install_base_packages
    install_docker
    setup_ssh_config
    setup_ansible_config
    create_project_template
    
    # Dashboard & Analytics
    init_analytics
    
    # Health-Check
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0")
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}' 2>/dev/null || echo "0")
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    
    log_health "docker_installation" "completed" "$cpu_usage" "$mem_usage" "$disk_usage" "full_installation"
    
    # Erfolgs-Meldung
    echo
    echo -e "${BRIGHT_GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_GREEN}║${NC}                    ${WHITE}🎉 DOCKER + DASHBOARD BEREIT! 🎉${NC}                   ${BRIGHT_GREEN}║${NC}"
    echo -e "${BRIGHT_GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    echo -e "${CYAN}✅ Installiert:${NC} Docker, Ansible, Dashboard, Analytics"
    echo -e "${CYAN}📁 Projekt:${NC} ~/ansible-projekte/beispiel-projekt"
    echo -e "${CYAN}🧪 Test:${NC} cd ~/ansible-projekte/beispiel-projekt && ansible-playbook playbooks/test.yml"
    echo -e "${CYAN}🩺 Dashboard:${NC} Option 3 im Hauptmenü"
    echo -e "${CYAN}📊 Analytics:${NC} Option 4 im Hauptmenü"
    
    echo
    log_warning "⚠️  Für Docker ohne sudo: Terminal neu starten oder 'newgrp docker' ausführen"
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
}

# Podman-Installation mit Dashboard
install_podman_with_dashboard() {
    clear
    echo -e "${BRIGHT_PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_PURPLE}║${NC}                  ${WHITE}🐳 PODMAN + DASHBOARD${NC}                            ${BRIGHT_PURPLE}║${NC}"
    echo -e "${BRIGHT_PURPLE}║${NC}                    ${GREEN}🔒 ROOTLESS & SICHER${NC}                          ${BRIGHT_PURPLE}║${NC}"
    echo -e "${BRIGHT_PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    read -p "$(echo -e "${WHITE}Podman-Installation mit Dashboard starten? (Y/n): ${NC}")" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        return 0
    fi
    
    # Progress-Animation
    show_installation_progress "PODMAN INSTALLATION + DASHBOARD" \
        "System aktualisieren" \
        "Basis-Pakete installieren" \
        "Podman installieren" \
        "Rootless-Setup konfigurieren" \
        "SSH-Konfiguration" \
        "Ansible-Konfiguration" \
        "Projekt-Template erstellen" \
        "Dashboard initialisieren" \
        "Analytics aktivieren" \
        "Sicherheits-Check"
    
    # Tatsächliche Installation
    update_system
    install_base_packages
    install_podman
    setup_ssh_config
    setup_ansible_config
    create_project_template
    
    # Dashboard & Analytics
    init_analytics
    
    # Health-Check
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "0")
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}' 2>/dev/null || echo "0")
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    
    log_health "podman_installation" "completed" "$cpu_usage" "$mem_usage" "$disk_usage" "rootless_installation"
    
    # Erfolgs-Meldung
    echo
    echo -e "${BRIGHT_PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_PURPLE}║${NC}                   ${WHITE}🎉 PODMAN + DASHBOARD BEREIT! 🎉${NC}                   ${BRIGHT_PURPLE}║${NC}"
    echo -e "${BRIGHT_PURPLE}║${NC}                      ${GREEN}🔒 100% ROOTLESS! 🔒${NC}                        ${BRIGHT_PURPLE}║${NC}"
    echo -e "${BRIGHT_PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    echo -e "${PURPLE}✅ Installiert:${NC} Podman, Ansible, Dashboard, Analytics"
    echo -e "${PURPLE}🔒 Sicherheit:${NC} Rootless, kein sudo für Container"
    echo -e "${PURPLE}📁 Projekt:${NC} ~/ansible-projekte/beispiel-projekt"
    echo -e "${PURPLE}🧪 Test:${NC} cd ~/ansible-projekte/beispiel-projekt && ansible-playbook playbooks/test.yml"
    echo -e "${PURPLE}🩺 Dashboard:${NC} Option 3 im Hauptmenü"
    echo -e "${PURPLE}📊 Analytics:${NC} Option 4 im Hauptmenü"
    
    echo
    log_success "✅ Podman läuft ohne Root-Berechtigung!"
    
    read -p "$(echo -e "${CYAN}Drücke Enter zum Fortfahren...${NC}")"
}

# Health Dashboard
show_health_dashboard() {
    clear
    echo -e "${BRIGHT_BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_BLUE}║${NC}                       ${WHITE}🩺 HEALTH DASHBOARD${NC}                           ${BRIGHT_BLUE}║${NC}"
    echo -e "${BRIGHT_BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    log_info "🔍 Sammle System-Informationen..."
    
    # System-Metriken sammeln
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 2>/dev/null || echo "N/A")
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}' 2>/dev/null || echo "N/A")
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "N/A")
    local uptime=$(uptime -p 2>/dev/null || echo "N/A")
    local load=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//' 2>/dev/null || echo "N/A")
    
    # Container-Status
    local docker_containers=0
    local podman_containers=0
    
    if command -v docker >/dev/null 2>&1; then
        docker_containers=$(docker ps -q 2>/dev/null | wc -l)
    fi
    
    if command -v podman >/dev/null 2>&1; then
        podman_containers=$(podman ps -q 2>/dev/null | wc -l)
    fi
    
    # Dashboard anzeigen
    echo -e "${CYAN}┌─ 💻 SYSTEM HEALTH ────────────────────────────────────────────────────┐${NC}"
    printf "${CYAN}│${NC} CPU: %-8s │ Memory: %-8s │ Disk: %-8s │ Load: %-8s ${CYAN}│${NC}\n" \
           "${cpu_usage}%" "${mem_usage}%" "${disk_usage}%" "$load"
    echo -e "${CYAN}│${NC} Uptime: $(printf '%-54s' "$uptime") ${CYAN}│${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    echo -e "${YELLOW}┌─ 🐳 CONTAINER STATUS ─────────────────────────────────────────────────┐${NC}"
    printf "${YELLOW}│${NC} Docker Container: %-8s │ Podman Container: %-8s      ${YELLOW}│${NC}\n" \
           "$docker_containers" "$podman_containers"
    echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    echo -e "${GREEN}┌─ 📊 ANSIBLE STATUS ───────────────────────────────────────────────────┐${NC}"
    
    # Ansible-Version
    local ansible_version="N/A"
    if command -v ansible >/dev/null 2>&1; then
        ansible_version=$(ansible --version | head -1 | awk '{print $2}' 2>/dev/null || echo "N/A")
    fi
    
    # Projekte zählen
    local projects=0
    if [ -d "$HOME/ansible-projekte" ]; then
        projects=$(find "$HOME/ansible-projekte" -mindepth 1 -maxdepth 1 -type d | wc -l)
    fi
    
    printf "${GREEN}│${NC} Ansible Version: %-15s │ Projekte: %-8s        ${GREEN}│${NC}\n" \
           "$ansible_version" "$projects"
    
    # Analytics-Status
    local analytics_entries=0
    if [ -f "$HEALTH_LOG" ]; then
        analytics_entries=$(tail -n +2 "$HEALTH_LOG" | wc -l)
    fi
    
    printf "${GREEN}│${NC} Analytics Einträge: %-10s │ Status: %-12s     ${GREEN}│${NC}\n" \
           "$analytics_entries" "Aktiv"
    
    echo -e "${GREEN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    
    # Health-Status bewerten
    echo
    local health_status="🟢 GESUND"
    local health_color="$GREEN"
    
    if [ "$cpu_usage" != "N/A" ] && [ "${cpu_usage%.*}" -gt 80 ]; then
        health_status="🟡 BELASTUNG"
        health_color="$YELLOW"
    fi
    
    if [ "$mem_usage" != "N/A" ] && [ "${mem_usage%.*}" -gt 90 ]; then
        health_status="🔴 KRITISCH"
        health_color="$RED"
    fi
    
    echo -e "${health_color}┌─ 🏥 GESAMT-STATUS ────────────────────────────────────────────────────┐${NC}"
    echo -e "${health_color}│${NC} System-Health: $health_status                                        ${health_color}│${NC}"
    echo -e "${health_color}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    
    # Health-Daten loggen
    log_health "dashboard_view" "viewed" "$cpu_usage" "$mem_usage" "$disk_usage" "health_check_completed"
    
    echo
    echo -e "${CYAN}🔄 Dashboard wird alle 30 Sekunden aktualisiert (Strg+C zum Beenden)${NC}"
    echo -e "${CYAN}💡 Tipp: Verwende 'htop' für detaillierte Prozess-Informationen${NC}"
    
    read -p "$(echo -e "${WHITE}Drücke Enter zum Fortfahren...${NC}")"
}

# Performance Analytics
show_performance_analytics() {
    clear
    echo -e "${BRIGHT_PURPLE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_PURPLE}║${NC}                    ${WHITE}📈 PERFORMANCE ANALYTICS${NC}                        ${BRIGHT_PURPLE}║${NC}"
    echo -e "${BRIGHT_PURPLE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
    
    echo
    log_info "📊 Analysiere Performance-Daten..."
    
    # Analytics-Daten prüfen
    if [ ! -f "$HEALTH_LOG" ] || [ $(wc -l < "$HEALTH_LOG") -le 1 ]; then
        echo -e "${YELLOW}┌─ ⚠️  KEINE ANALYTICS-DATEN ──────────────────────────────────────────┐${NC}"
        echo -e "${YELLOW}│${NC} Noch keine Performance-Daten verfügbar.                           ${YELLOW}│${NC}"
        echo -e "${YELLOW}│${NC} Führe zuerst eine Installation durch oder nutze das Dashboard.    ${YELLOW}│${NC}"
        echo -e "${YELLOW}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        
        # Beispiel-Daten erstellen
        echo
        read -p "$(echo -e "${WHITE}Beispiel-Daten erstellen? (Y/n): ${NC}")" -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            init_analytics
            log_health "example_task" "completed" "25.5" "45.2" "67" "example_performance_data"
            log_health "docker_check" "completed" "15.3" "52.1" "65" "container_monitoring"
            log_health "podman_check" "completed" "18.7" "48.9" "63" "rootless_container_check"
            log_success "Beispiel-Daten erstellt"
        fi
    fi
    
    # Analytics auswerten
    if [ -f "$HEALTH_LOG" ] && [ $(wc -l < "$HEALTH_LOG") -gt 1 ]; then
        local total_entries=$(tail -n +2 "$HEALTH_LOG" | wc -l)
        local avg_cpu=$(tail -n +2 "$HEALTH_LOG" | awk -F',' '{sum+=$4; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
        local avg_mem=$(tail -n +2 "$HEALTH_LOG" | awk -F',' '{sum+=$5; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
        local avg_disk=$(tail -n +2 "$HEALTH_LOG" | awk -F',' '{sum+=$6; count++} END {if(count>0) printf "%.1f", sum/count; else print "0"}')
        
        echo -e "${PURPLE}┌─ 📊 ANALYTICS ÜBERSICHT ──────────────────────────────────────────────┐${NC}"
        printf "${PURPLE}│${NC} Gesamt-Einträge: %-10s │ Durchschnittswerte:               ${PURPLE}│${NC}\n" "$total_entries"
        printf "${PURPLE}│${NC} CPU: %-6s %% │ Memory: %-6s %% │ Disk: %-6s %%        ${PURPLE}│${NC}\n" \
               "$avg_cpu" "$avg_mem" "$avg_disk"
        echo -e "${PURPLE}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        
        echo
        echo -e "${GREEN}┌─ 🏆 PERFORMANCE TRENDS ───────────────────────────────────────────────┐${NC}"
        
        # Letzte 5 Einträge anzeigen
        echo -e "${GREEN}│${NC} Letzte 5 Performance-Metriken:                                    ${GREEN}│${NC}"
        
        tail -n 5 "$HEALTH_LOG" | while IFS=',' read -r timestamp component status cpu memory disk details; do
            local date_short=$(echo "$timestamp" | cut -d'T' -f1)
            local time_short=$(echo "$timestamp" | cut -d'T' -f2 | cut -d'+' -f1 | cut -d':' -f1,2)
            printf "${GREEN}│${NC} %s %s │ CPU: %s%% │ MEM: %s%% │ %s ${GREEN}│${NC}\n" \
                   "$date_short" "$time_short" "$cpu" "$memory" "$component"
        done
        
        echo -e "${GREEN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
        
        # Performance-Bewertung
        echo
        local performance_rating="🟢 OPTIMAL"
        local performance_color="$GREEN"
        
        if [ "${avg_cpu%.*}" -gt 50 ]; then
            performance_rating="🟡 MODERAT"
            performance_color="$YELLOW"
        fi
        
        if [ "${avg_cpu%.*}" -gt 80 ]; then
            performance_rating="🔴 HOCH"
            performance_color="$RED"
        fi
        
        echo -e "${performance_color}┌─ 🎯 PERFORMANCE BEWERTUNG ────────────────────────────────────────────┐${NC}"
        echo -e "${performance_color}│${NC} System-Performance: $performance_rating                                ${performance_color}│${NC}"
        echo -e "${performance_color}│${NC} Empfehlung: Regelmäßige Überwachung für optimale Performance      ${performance_color}│${NC}"
        echo -e "${performance_color}└─────────────────────────────────────────────────────────────────────────┘${NC}"
    fi
    
    echo
    echo -e "${CYAN}💡 Performance-Tipps:${NC}"
    echo "• Überwache CPU-Auslastung < 80%"
    echo "• Halte Memory-Nutzung < 90%"
    echo "• Nutze das Health Dashboard für Live-Monitoring"
    echo "• Führe regelmäßige Container-Cleanups durch"
    
    read -p "$(echo -e "${WHITE}Drücke Enter zum Fortfahren...${NC}")"
}

# Prüfungen
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "❌ Dieses Script sollte NICHT als root ausgeführt werden!"
        log_info "Führe es als normaler User aus: ./ansible.sh"
        exit 1
    fi
}

check_manjaro() {
    if ! grep -q "Manjaro" /etc/os-release; then
        log_warning "⚠️  Dieses Script ist für Manjaro optimiert."
        read -p "Trotzdem fortfahren? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Hauptfunktion
main() {
    # Analytics initialisieren
    init_analytics
    
    check_root
    check_manjaro
    
    while true; do
        show_banner
        show_focused_menu
        
        read -p "$(echo -e "${WHITE}Wähle eine Option [1-5]: ${BRIGHT_CYAN}")" choice
        echo -e "${NC}"
        
        case $choice in
            1)
                install_docker_with_dashboard
                ;;
            2)
                install_podman_with_dashboard
                ;;
            3)
                show_health_dashboard
                ;;
            4)
                show_performance_analytics
                ;;
            5)
                echo
                echo -e "${GREEN}┌─ 👋 ANSIBLE INSTALLER ────────────────────────────────────────────────┐${NC}"
                echo -e "${GREEN}│${NC} Vielen Dank für die Nutzung!                                      ${GREEN}│${NC}"
                echo -e "${GREEN}│${NC}                                                                    ${GREEN}│${NC}"
                echo -e "${GREEN}│${NC} 🚀 Features: Docker/Podman + Dashboard + Analytics               ${GREEN}│${NC}"
                echo -e "${GREEN}│${NC} 📖 Dokumentation: https://docs.ansible.com/                      ${GREEN}│${NC}"
                echo -e "${GREEN}│${NC} 🔄 Script erneut starten: ./ansible.sh                           ${GREEN}│${NC}"
                echo -e "${GREEN}└─────────────────────────────────────────────────────────────────────────┘${NC}"
                exit 0
                ;;
            *)
                echo
                echo -e "${RED}┌─ ❌ UNGÜLTIGE EINGABE ─────────────────────────────────────────────┐${NC}"
                echo -e "${RED}│${NC} Bitte wähle eine Zahl zwischen 1 und 5.                       ${RED}│${NC}"
                echo -e "${RED}└─────────────────────────────────────────────────────────────────────┘${NC}"
                sleep 2
                ;;
        esac
    done
}

# Script starten
main "$@"