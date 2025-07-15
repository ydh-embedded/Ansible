#!/bin/bash

# =============================================================================
# Ansible Installation Script für Manjaro Linux
# =============================================================================
# Dieses Script installiert Ansible und alle benötigten Dependencies
# Autor: Claude (Anthropic)
# Version: 1.0
# =============================================================================

set -e  # Script bei Fehlern beenden

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Banner anzeigen
show_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                   ANSIBLE INSTALLER v2.0                    ║
║                   für Manjaro Linux                          ║
║                                                               ║
║  🚀 NEU: Automatische KW-Container + Vollinstallation        ║
║  🛠️  NEU: Erweiterte Fehlerbehandlung + Health-Checks        ║
║  📦 NEU: Optimierte pip-Installation ohne Warnungen         ║
║  🐳 NEU: Podman Rootless Alternative (KEIN sudo!)           ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    # Aktuelle Kalenderwoche anzeigen
    local current_container=$(get_current_container_name)
    log_info "Aktuelle Kalenderwoche: $(date +%V) / Jahr: $(date +%Y)"
    log_info "Standard Container-Name: $current_container"
    
    # Container-Engine-Optionen anzeigen
    echo
    log_info "🐳 Verfügbare Container-Engines:"
    if command -v docker >/dev/null 2>&1; then
        if docker ps >/dev/null 2>&1; then
            echo "• ✅ Docker (verfügbar)"
        else
            echo "• ⚠️  Docker (Berechtigungsprobleme möglich)"
        fi
    else
        echo "• ❌ Docker (nicht installiert)"
    fi
    
    if command -v podman >/dev/null 2>&1; then
        if podman info >/dev/null 2>&1; then
            echo "• ✅ Podman (rootless verfügbar)"
        else
            echo "• ⚠️  Podman (Setup erforderlich)"
        fi
    else
        echo "• ❌ Podman (nicht installiert)"
    fi
    
    # Prüfen ob Container bereits existiert
    if command -v docker &> /dev/null && docker ps -a --format "{{.Names}}" | grep -q "^${current_container}$"; then
        local status=$(docker inspect -f '{{.State.Status}}' "$current_container" 2>/dev/null)
        case $status in
            "running")
                log_success "✅ Docker-Container '$current_container' läuft bereits!"
                
                # Quick Health-Check wenn Container läuft
                if docker exec "$current_container" test -f /home/developer/health-check.sh 2>/dev/null; then
                    if docker exec "$current_container" /home/developer/health-check.sh >/dev/null 2>&1; then
                        log_success "🩺 Health-Check: OK"
                    else
                        log_warning "🩺 Health-Check: Probleme detected"
                    fi
                fi
                ;;
            "exited")
                log_warning "⏸️  Docker-Container '$current_container' ist gestoppt"
                ;;
            *)
                log_info "📦 Docker-Container '$current_container' existiert ($status)"
                ;;
        esac
    elif command -v podman &> /dev/null && podman ps -a --format "{{.Names}}" | grep -q "^${current_container}$"; then
        local status=$(podman inspect -f '{{.State.Status}}' "$current_container" 2>/dev/null)
        case $status in
            "running")
                log_success "✅ Podman-Container '$current_container' läuft bereits!"
                ;;
            "exited")
                log_warning "⏸️  Podman-Container '$current_container' ist gestoppt"
                ;;
            *)
                log_info "📦 Podman-Container '$current_container' existiert ($status)"
                ;;
        esac
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

# Menü anzeigen
show_menu() {
    echo
    log_info "Was möchtest du installieren?"
    echo "1) Basis-Installation (Ansible + essentials)"
    echo "2) Vollständige Installation (+ Docker, VSCode, Tools)"
    echo "3) Minimale Installation (nur Ansible)"
    echo "4) Custom Installation (einzeln auswählen)"
    echo "5) Nur Testumgebung einrichten"
    echo "6) In Docker-Container ausführen (isoliert)"
    echo "7) 🚀 AUTO: Neuer KW-Container + Vollinstallation (Docker)"
    echo "8) 🐳 AUTO: Neuer KW-Container + Vollinstallation (Podman - ROOTLESS)"
    echo "9) Container-Management (anzeigen/löschen)"
    echo "10) Beenden"
    echo
}

# Paket-Installation mit Fehlerbehandlung
install_package() {
    local package=$1
    log_info "Installiere $package..."
    
    if sudo pacman -S --noconfirm "$package"; then
        log_success "$package erfolgreich installiert"
        return 0
    else
        log_error "Fehler beim Installieren von $package"
        return 1
    fi
}

# AUR Helper installieren
install_aur_helper() {
    if command -v yay &> /dev/null; then
        log_success "yay ist bereits installiert"
        return 0
    fi
    
    log_info "Installiere yay (AUR Helper)..."
    
    # Git klonen und kompilieren
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    
    if command -v yay &> /dev/null; then
        log_success "yay erfolgreich installiert"
        return 0
    else
        log_error "yay Installation fehlgeschlagen"
        return 1
    fi
}

# System aktualisieren
update_system() {
    log_info "Aktualisiere System..."
    sudo pacman -Syu --noconfirm
    log_success "System aktualisiert"
}

# Basis-Pakete installieren
install_base_packages() {
    log_info "Installiere Basis-Pakete..."
    
    local packages=(
        "ansible"
        "python"
        "python-pip"
        "openssh"
        "git"
        "curl"
        "vim"
        "tree"
    )
    
    for package in "${packages[@]}"; do
        install_package "$package"
    done
    
    # Python-Module
    log_info "Installiere Python-Module..."
    pip install --user jinja2 paramiko PyYAML cryptography ansible-lint
    
    log_success "Basis-Installation abgeschlossen"
}

# Docker installieren
install_docker() {
    log_info "Installiere Docker..."
    
    install_package "docker"
    install_package "docker-compose"
    
    # Docker Service aktivieren
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # User zu docker-Gruppe hinzufügen
    sudo usermod -aG docker "$USER"
    
    log_success "Docker installiert"
    log_warning "Bitte melde dich ab und wieder an, um Docker ohne sudo zu nutzen"
}

# VSCode installieren
install_vscode() {
    log_info "Installiere Visual Studio Code..."
    
    if ! install_aur_helper; then
        log_error "Kann VSCode nicht installieren (yay fehlt)"
        return 1
    fi
    
    yay -S --noconfirm visual-studio-code-bin
    log_success "VSCode installiert"
}

# Zusätzliche Tools installieren
install_additional_tools() {
    log_info "Installiere zusätzliche Tools..."
    
    local packages=(
        "yamllint"
        "nano"
        "htop"
        "wget"
        "unzip"
    )
    
    for package in "${packages[@]}"; do
        install_package "$package"
    done
    
    # Python-Tools
    pip install --user molecule[docker] awxkit
    
    log_success "Zusätzliche Tools installiert"
}

# SSH-Schlüssel erstellen
setup_ssh_keys() {
    if [ -f ~/.ssh/id_rsa ]; then
        log_info "SSH-Schlüssel existiert bereits"
        return 0
    fi
    
    log_info "Erstelle SSH-Schlüssel..."
    read -p "E-Mail für SSH-Schlüssel eingeben: " email
    
    if [ -z "$email" ]; then
        email="ansible@$(hostname)"
    fi
    
    ssh-keygen -t rsa -b 4096 -C "$email" -f ~/.ssh/id_rsa -N ""
    
    # SSH-Agent starten
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_rsa
    
    log_success "SSH-Schlüssel erstellt"
    echo "Öffentlicher Schlüssel:"
    cat ~/.ssh/id_rsa.pub
}

# Ansible-Konfiguration erstellen
setup_ansible_config() {
    log_info "Erstelle Ansible-Konfiguration..."
    
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
    
    log_info "Erstelle Projekt-Template..."
    
    mkdir -p "$project_dir/webserver-beispiel"/{inventory,playbooks,templates,files,group_vars,host_vars}
    
    # Beispiel-Inventory
    cat > "$project_dir/webserver-beispiel/inventory/hosts.yml" << 'EOF'
all:
  children:
    webservers:
      hosts:
        localhost:
          ansible_connection: local
      vars:
        ansible_user: ansible
        nginx_port: 80
EOF
    
    # Beispiel-Playbook
    cat > "$project_dir/webserver-beispiel/playbooks/test.yml" << 'EOF'
---
- name: Ansible Test
  hosts: localhost
  connection: local
  tasks:
    - name: Test-Datei erstellen
      file:
        path: /tmp/ansible-test.txt
        state: touch
    
    - name: Erfolg melden
      debug:
        msg: "Ansible funktioniert perfekt!"
EOF
    
    # README erstellen
    cat > "$project_dir/webserver-beispiel/README.md" << 'EOF'
# Ansible Beispiel-Projekt

## Test ausführen
```bash
cd ansible-projekte/webserver-beispiel
ansible-playbook playbooks/test.yml
```

## Webserver-Projekt kopieren
Das vollständige Webserver-Beispiel findest du in der Anleitung.
EOF
    
    log_success "Projekt-Template erstellt in $project_dir"
}

# Docker Test-Container starten
setup_docker_test() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker ist nicht installiert"
        return 1
    fi
    
    log_info "Starte Docker Test-Container..."
    
    # Ubuntu Test-Container
    docker run -d --name ansible-test \
        --privileged \
        -p 2222:22 \
        -p 8080:80 \
        ubuntu:22.04 \
        /bin/bash -c "
            apt update && 
            apt install -y openssh-server sudo python3 &&
            useradd -m -s /bin/bash ansible &&
            echo 'ansible:ansible' | chpasswd &&
            echo 'ansible ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers &&
            mkdir -p /home/ansible/.ssh &&
            service ssh start &&
            tail -f /dev/null
        "
    
    sleep 5
    
    # SSH-Schlüssel zum Container kopieren
    if [ -f ~/.ssh/id_rsa.pub ]; then
        docker exec ansible-test bash -c "
            mkdir -p /home/ansible/.ssh &&
            chown ansible:ansible /home/ansible/.ssh
        "
        docker cp ~/.ssh/id_rsa.pub ansible-test:/home/ansible/.ssh/authorized_keys
        docker exec ansible-test chown ansible:ansible /home/ansible/.ssh/authorized_keys
    fi
    
    log_success "Docker Test-Container gestartet"
    log_info "Test mit: ansible ansible-test -i 'localhost:2222,' -u ansible -m ping"
}

# Docker prüfen und installieren falls nötig
ensure_docker() {
    log_info "🐳 Prüfe Docker-Setup..."
    
    # Docker installiert?
    if ! command -v docker &> /dev/null; then
        log_info "Docker ist nicht installiert. Installiere Docker..."
        install_package "docker"
        sudo systemctl enable --now docker
        
        # Warten bis Docker läuft
        sleep 5
        
        # User zur Gruppe hinzufügen
        sudo usermod -aG docker "$USER"
        log_success "Docker installiert und User zur docker-Gruppe hinzugefügt"
    fi
    
    # Docker-Service läuft?
    if ! systemctl is-active --quiet docker; then
        log_info "Starte Docker-Service..."
        sudo systemctl start docker
        sleep 3
    fi
    
    # Prüfe ob User in docker-Gruppe ist
    if ! groups | grep -q docker; then
        log_info "Füge User zur docker-Gruppe hinzu..."
        sudo usermod -aG docker "$USER"
        log_success "User zur docker-Gruppe hinzugefügt"
    fi
    
    # Docker-Berechtigung testen
    log_info "Teste Docker-Berechtigung..."
    if docker ps >/dev/null 2>&1; then
        log_success "✅ Docker funktioniert ohne sudo!"
        return 0
    fi
    
    log_warning "❌ Docker-Gruppe ist noch nicht aktiv in dieser Session"
    
    echo
    log_info "🔧 Lösungen (OHNE sudo):"
    echo "1) 🔄 Session-Gruppe aktualisieren (empfohlen)"
    echo "2) 🆕 Neues Terminal öffnen"  
    echo "3) 🔐 Temporäre Socket-Berechtigung"
    echo "4) 🐳 Docker Rootless Mode verwenden"
    echo "5) ⚠️  Als Fallback: sudo verwenden"
    echo
    
    read -p "Lösung wählen [1-5]: " -n 1 -r
    echo
    
    case $REPLY in
        1|"")
            log_info "Aktiviere docker-Gruppe in aktueller Session..."
            log_info "Script wird mit korrekten Berechtigungen neu gestartet..."
            exec newgrp docker -c "$0 $*"
            ;;
        2)
            log_info "Bitte öffne ein neues Terminal und führe das Script dort aus:"
            echo "  ./ansible.sh"
            echo
            echo "In neuem Terminal sollte docker ohne sudo funktionieren."
            exit 0
            ;;
        3)
            log_info "Setze temporäre Socket-Berechtigung (session-lokal)..."
            
            # Aktuelle Socket-Berechtigung sichern
            local original_perms=$(stat -c "%a" /var/run/docker.sock 2>/dev/null)
            
            # Temporär Socket für User zugänglich machen
            if sudo chmod g+rw /var/run/docker.sock 2>/dev/null; then
                log_info "Socket-Berechtigung temporär angepasst"
                
                # Testen
                if docker ps >/dev/null 2>&1; then
                    log_success "✅ Docker funktioniert jetzt ohne sudo!"
                    
                    # Warnung über temporäre Lösung
                    log_warning "⚠️  Diese Lösung ist nur für diese Session gültig"
                    echo "Für dauerhafte Lösung: Terminal neu starten oder neu anmelden"
                    
                    return 0
                else
                    log_error "Socket-Fix funktionierte nicht"
                fi
                
                # Berechtigung zurücksetzen falls möglich
                if [ -n "$original_perms" ]; then
                    sudo chmod "$original_perms" /var/run/docker.sock 2>/dev/null || true
                fi
            else
                log_error "Konnte Socket-Berechtigung nicht ändern"
            fi
            ;;
        4)
            log_info "🐳 Docker Rootless Mode Setup..."
            
            # Prüfen ob rootless möglich ist
            if command -v dockerd-rootless-setuptool.sh >/dev/null 2>&1; then
                echo "Docker Rootless ist verfügbar!"
                echo
                echo "Setup-Schritte für Rootless Docker:"
                echo "1. dockerd-rootless-setuptool.sh install"
                echo "2. export PATH=/home/$USER/bin:\$PATH"
                echo "3. export DOCKER_HOST=unix:///run/user/\$(id -u)/docker.sock"
                echo "4. systemctl --user enable docker"
                echo "5. systemctl --user start docker"
                echo
                
                read -p "Rootless Docker jetzt einrichten? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log_info "Richte Docker Rootless ein..."
                    
                    # Rootless-Setup ausführen
                    if dockerd-rootless-setuptool.sh install; then
                        # Umgebungsvariablen setzen
                        export PATH="/home/$USER/bin:$PATH"
                        export DOCKER_HOST="unix:///run/user/$(id -u)/docker.sock"
                        
                        # Service starten
                        systemctl --user enable docker
                        systemctl --user start docker
                        
                        sleep 3
                        
                        # Testen
                        if docker ps >/dev/null 2>&1; then
                            log_success "✅ Docker Rootless funktioniert!"
                            
                            # Bashrc anpassen für permanente Lösung
                            echo "export PATH=\"/home/$USER/bin:\$PATH\"" >> ~/.bashrc
                            echo "export DOCKER_HOST=\"unix:///run/user/\$(id -u)/docker.sock\"" >> ~/.bashrc
                            
                            log_info "Docker Rootless ist jetzt aktiv und permanent konfiguriert"
                            return 0
                        else
                            log_error "Rootless Docker Test fehlgeschlagen"
                        fi
                    else
                        log_error "Rootless Docker Setup fehlgeschlagen"
                    fi
                fi
            else
                log_warning "Docker Rootless ist nicht verfügbar"
                echo "Installation: sudo pacman -S docker-rootless-extras"
            fi
            ;;
        5)
            log_warning "Verwende sudo als Fallback (nicht optimal)"
            log_info "Hinweis: Für bessere Lösung Terminal neu starten"
            return 0  # Erlaubt sudo-Verwendung
            ;;
        *)
            log_error "Ungültige Auswahl"
            return 1
            ;;
    esac
    
    # Falls alle Lösungen fehlschlagen
    log_error "Docker-Setup konnte nicht ohne sudo konfiguriert werden"
    echo
    log_info "🔍 Manuelle Lösungen:"
    echo "1. Terminal neu starten: Ctrl+Shift+T"
    echo "2. Session neu: exec bash"
    echo "3. Neu anmelden: logout/login"
    echo "4. System neustarten"
    echo "5. Rootless Docker: sudo pacman -S docker-rootless-extras"
    echo
    
    read -p "Mit sudo-Fallback fortfahren? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_warning "Verwende sudo-Fallback"
        return 0
    fi
    
    return 1
}

# Aktuelle Kalenderwoche ermitteln
get_calendar_week() {
    # 2-stelliges Jahr + KW + Woche
    date +"%yKW%V"
}

# Container-Name für aktuelle KW generieren
get_current_container_name() {
    echo "$(get_calendar_week)-docker"
}

# Alle Ansible-Container auflisten
list_ansible_containers() {
    log_info "Ansible-Container im System:"
    echo
    
    local found_containers=false
    
    # Docker-Container
    if command -v docker >/dev/null 2>&1; then
        local docker_containers=$(docker ps -a --filter "name=-docker" --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}\t{{.Ports}}" 2>/dev/null)
        
        if [ -n "$docker_containers" ] && [ "$docker_containers" != "NAMES	STATUS	CREATED AT	PORTS" ]; then
            echo "🐳 Docker-Container:"
            echo "$docker_containers"
            echo
            found_containers=true
            
            # Docker Health-Status
            echo "🩺 Docker Container-Health:"
            docker ps -a --filter "name=-docker" --format "{{.Names}}" 2>/dev/null | while read container_name; do
                if [ -n "$container_name" ]; then
                    local status=$(docker inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null)
                    printf "  %-20s " "$container_name:"
                    
                    case $status in
                        "running")
                            echo -n "🟢 Läuft"
                            if docker exec "$container_name" test -f /home/developer/health-check.sh 2>/dev/null; then
                                if docker exec "$container_name" /home/developer/health-check.sh >/dev/null 2>&1; then
                                    echo " (✅ Gesund)"
                                else
                                    echo " (⚠️  Health-Check failed)"
                                fi
                            else
                                echo " (❓ Alter Container)"
                            fi
                            ;;
                        "exited")
                            echo "🔴 Gestoppt"
                            ;;
                        *)
                            echo "🟡 $status"
                            ;;
                    esac
                fi
            done
            echo
        fi
    fi
    
    # Podman-Container
    if command -v podman >/dev/null 2>&1; then
        local podman_containers=$(podman ps -a --filter "name=ansible" --format "table {{.Names}}\t{{.Status}}\t{{.CreatedAt}}\t{{.Ports}}" 2>/dev/null)
        
        if [ -n "$podman_containers" ] && [ "$podman_containers" != "NAMES	STATUS	CREATED AT	PORTS" ]; then
            echo "🐳 Podman-Container (rootless):"
            echo "$podman_containers"
            echo
            found_containers=true
            
            # Podman Health-Status
            echo "🩺 Podman Container-Health:"
            podman ps -a --filter "name=ansible" --format "{{.Names}}" 2>/dev/null | while read container_name; do
                if [ -n "$container_name" ]; then
                    local status=$(podman inspect -f '{{.State.Status}}' "$container_name" 2>/dev/null)
                    printf "  %-20s " "$container_name:"
                    
                    case $status in
                        "running")
                            echo "🟢 Läuft (rootless)"
                            ;;
                        "exited")
                            echo "🔴 Gestoppt (rootless)"
                            ;;
                        *)
                            echo "🟡 $status (rootless)"
                            ;;
                    esac
                fi
            done
            echo
        fi
    fi
    
    if [ "$found_containers" = false ]; then
        echo "  Keine Ansible-Container gefunden."
        return 1
    fi
    
    return 0
}

# Container-Management Menü
manage_containers() {
    while true; do
        echo
        log_info "Container-Management:"
        
        if list_ansible_containers; then
            echo
            echo "Aktionen:"
            echo "1) Container starten"
            echo "2) Container stoppen" 
            echo "3) Container löschen"
            echo "4) In Container einloggen"
            echo "5) Container-Details anzeigen"
            echo "6) Alte Container (>4 Wochen) löschen"
            echo "7) Container-Engine wählen (Docker/Podman)"
            echo "8) Zurück zum Hauptmenü"
        else
            echo
            echo "Optionen:"
            echo "1) Neuen Docker-Container erstellen"
            echo "2) Neuen Podman-Container erstellen"
            echo "3) Zurück zum Hauptmenü"
        fi
        
        read -p "Wähle eine Option: " choice
        
        if list_ansible_containers >/dev/null 2>&1; then
            # Container vorhanden
            case $choice in
                1)
                    echo
                    echo "Container-Engine:"
                    echo "1) Docker-Container starten"
                    echo "2) Podman-Container starten"
                    read -p "Engine [1-2]: " engine
                    read -p "Container-Name eingeben: " container_name
                    
                    if [ -n "$container_name" ]; then
                        case $engine in
                            1) docker start "$container_name" && log_success "Docker-Container '$container_name' gestartet" ;;
                            2) podman start "$container_name" && log_success "Podman-Container '$container_name' gestartet" ;;
                            *) log_error "Ungültige Engine-Auswahl" ;;
                        esac
                    fi
                    ;;
                2)
                    echo
                    echo "Container-Engine:"
                    echo "1) Docker-Container stoppen"
                    echo "2) Podman-Container stoppen"
                    read -p "Engine [1-2]: " engine
                    read -p "Container-Name eingeben: " container_name
                    
                    if [ -n "$container_name" ]; then
                        case $engine in
                            1) docker stop "$container_name" && log_success "Docker-Container '$container_name' gestoppt" ;;
                            2) podman stop "$container_name" && log_success "Podman-Container '$container_name' gestoppt" ;;
                            *) log_error "Ungültige Engine-Auswahl" ;;
                        esac
                    fi
                    ;;
                3)
                    cleanup_containers
                    ;;
                4)
                    echo
                    echo "Container-Engine:"
                    echo "1) Docker-Container"
                    echo "2) Podman-Container"
                    read -p "Engine [1-2]: " engine
                    read -p "Container-Name eingeben: " container_name
                    
                    if [ -n "$container_name" ]; then
                        log_info "Verbinde mit Container '$container_name'..."
                        case $engine in
                            1) docker exec -it "$container_name" /bin/bash ;;
                            2) podman exec -it "$container_name" su - developer ;;
                            *) log_error "Ungültige Engine-Auswahl" ;;
                        esac
                    fi
                    ;;
                5)
                    echo
                    echo "Container-Engine:"
                    echo "1) Docker-Container"
                    echo "2) Podman-Container"
                    read -p "Engine [1-2]: " engine
                    read -p "Container-Name eingeben: " container_name
                    
                    if [ -n "$container_name" ]; then
                        case $engine in
                            1) 
                                if command -v jq >/dev/null 2>&1; then
                                    docker inspect "$container_name" | jq '.[0] | {Name: .Name, Status: .State.Status, Created: .Created, Ports: .NetworkSettings.Ports}'
                                else
                                    docker inspect "$container_name"
                                fi
                                ;;
                            2) 
                                if command -v jq >/dev/null 2>&1; then
                                    podman inspect "$container_name" | jq '.[0] | {Name: .Name, Status: .State.Status, Created: .Created, Ports: .NetworkSettings.Ports}'
                                else
                                    podman inspect "$container_name"
                                fi
                                ;;
                            *) log_error "Ungültige Engine-Auswahl" ;;
                        esac
                    fi
                    ;;
                6)
                    cleanup_containers
                    ;;
                7)
                    echo
                    log_info "Verfügbare Container-Engines:"
                    if command -v docker >/dev/null 2>&1; then
                        if docker ps >/dev/null 2>&1; then
                            echo "✅ Docker (verfügbar)"
                        else
                            echo "⚠️  Docker (Berechtigungsprobleme)"
                        fi
                    else
                        echo "❌ Docker (nicht installiert)"
                    fi
                    
                    if command -v podman >/dev/null 2>&1; then
                        if podman info >/dev/null 2>&1; then
                            echo "✅ Podman (rootless verfügbar)"
                        else
                            echo "⚠️  Podman (Setup erforderlich)"
                        fi
                    else
                        echo "❌ Podman (nicht installiert)"
                    fi
                    
                    echo
                    echo "Docker: Standard, weit verbreitet, evtl. sudo erforderlich"
                    echo "Podman: Rootless, sicherer, kein sudo, daemon-frei"
                    
                    read -p "Drücke Enter zum Fortfahren..."
                    ;;
                8)
                    return 0
                    ;;
                *)
                    log_error "Ungültige Auswahl"
                    ;;
            esac
        else
            # Keine Container vorhanden
            case $choice in
                1)
                    create_weekly_container_auto
                    ;;
                2)
                    create_podman_container_auto
                    ;;
                3)
                    return 0
                    ;;
                *)
                    log_error "Ungültige Auswahl"
                    ;;
            esac
        fi
    done
}

# Alte Container löschen (älter als 4 Wochen)
cleanup_old_containers() {
    log_info "Suche nach alten Containern (älter als 4 Wochen)..."
    
    local current_year=$(date +%y)  # 2-stelliges Jahr
    local current_week=$(date +%V)
    local cutoff_week=$((current_week - 4))
    
    # Über Jahreswechsel hinweg berücksichtigen
    if [ $cutoff_week -le 0 ]; then
        cutoff_week=$((52 + cutoff_week))
        current_year=$((current_year - 1))
        # 2-stelliges Jahr Format beibehalten
        current_year=$(printf "%02d" $current_year)
    fi
    
    local old_containers=$(docker ps -a --filter "name=-docker" --format "{{.Names}}" | while read container; do
        # Neues Pattern: 25KW28-docker
        if [[ $container =~ ([0-9]{2})KW([0-9]+)-docker ]]; then
            local year=${BASH_REMATCH[1]}
            local week=${BASH_REMATCH[2]}
            
            # Jahreszahl in 4-stellig für Vergleich umwandeln
            local full_year=$((2000 + 10#$year))
            local current_full_year=$((2000 + 10#$current_year))
            
            # Einfache Altersberechnung (kann über Jahresgrenzen ungenau sein)
            if [ $full_year -lt $current_full_year ] || ([ $full_year -eq $current_full_year ] && [ $((10#$week)) -lt $cutoff_week ]); then
                echo $container
            fi
        fi
    done)
    
    if [ -z "$old_containers" ]; then
        log_info "Keine alten Container gefunden."
        return 0
    fi
    
    echo "Gefundene alte Container:"
    echo "$old_containers"
    echo
    
    read -p "Diese Container löschen? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$old_containers" | while read container; do
            docker rm -f "$container" && log_success "Container '$container' gelöscht"
        done
    fi
}

# Podman Rootless Container erstellen
create_podman_container_auto() {
    local container_name=$(get_current_container_name)
    
    log_info "🐳 Podman Rootless Container-Erstellung (KEIN sudo!)"
    log_info "Container-Name: $container_name"
    log_info "Kalenderwoche: $(date +%V) / Jahr: $(date +%Y)"
    
    # Podman installieren falls nötig
    if ! command -v podman >/dev/null 2>&1; then
        log_info "Podman ist nicht installiert. Installiere..."
        
        if command -v yay >/dev/null 2>&1; then
            yay -S --noconfirm podman
        elif command -v paru >/dev/null 2>&1; then
            paru -S --noconfirm podman
        else
            log_warning "Bitte installiere Podman manuell:"
            echo "sudo pacman -S podman"
            echo "Oder: yay -S podman"
            return 1
        fi
    fi
    
    # Rootless-Setup prüfen
    if ! podman info >/dev/null 2>&1; then
        log_info "Richte Podman Rootless ein..."
        
        # Subuid/subgid prüfen
        if ! grep -q "^$USER:" /etc/subuid 2>/dev/null; then
            log_error "Subuid/subgid nicht konfiguriert!"
            echo
            echo "Führe diese Befehle aus:"
            echo "sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER"
            echo "podman system migrate"
            echo "newgrp $(id -gn)"
            echo
            echo "Dann Script neu starten."
            return 1
        fi
        
        podman system migrate 2>/dev/null || true
    fi
    
    log_success "✅ Podman Rootless ist einsatzbereit!"
    
    # Container-Port
    local ssh_port=$((3280 + $(date +%V)))  # Andere Ports als Docker
    
    # Prüfen ob Container existiert
    if podman ps -a --format "{{.Names}}" | grep -q "^${container_name}$"; then
        log_warning "Container '$container_name' existiert bereits"
        
        read -p "Verwenden (1) oder neu erstellen (2)? [1/2]: " -n 1 -r
        echo
        
        if [[ $REPLY == "2" ]]; then
            podman rm -f "$container_name" 2>/dev/null || true
        else
            if [ "$(podman inspect -f '{{.State.Status}}' "$container_name")" != "running" ]; then
                podman start "$container_name"
            fi
            
            log_info "Verbinde mit bestehendem Container..."
            podman exec -it "$container_name" su - developer
            return 0
        fi
    fi
    
    log_info "🔨 Erstelle Ansible-Container mit Podman (rootless)..."
    
    # Container erstellen (ohne sudo!)
    if podman run -d \
        --name "$container_name" \
        --hostname "ansible-$(date +%yKW%V)" \
        -p ${ssh_port}:22 \
        -v "${container_name}-projects:/home/developer/ansible-projekte:Z" \
        -v "${container_name}-ssh:/home/developer/.ssh:Z" \
        --security-opt label=disable \
        archlinux:latest \
        /bin/bash -c "
            # System-Update ohne Interaktion
            pacman -Syu --noconfirm
            
            # Basis-Pakete installieren
            pacman -S --noconfirm \
                sudo git curl vim nano openssh \
                python python-pip ansible \
                yamllint tree htop jq
            
            # User erstellen
            useradd -m -s /bin/bash developer
            echo 'developer:developer' | chpasswd
            echo 'developer ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
            
            # SSH-Setup
            ssh-keygen -A
            mkdir -p /run/sshd
            echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
            echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config
            
            # Python-Module (ohne Warnungen)
            pip install --root-user-action=ignore --break-system-packages \
                jinja2 paramiko PyYAML cryptography ansible-lint
            
            # User-Setup
            su - developer -c '
                mkdir -p ansible-projekte/webserver-beispiel/{inventory,playbooks,templates,files}
                
                # Ansible-Config
                mkdir -p .ansible
                cat > .ansible/ansible.cfg << \"CONFEOF\"
[defaults]
host_key_checking = False
inventory = ./inventory/hosts.yml
stdout_callback = yaml
retry_files_enabled = False
gathering = smart

[privilege_escalation]
become = True
become_method = sudo
become_ask_pass = False
CONFEOF
                
                # Test-Inventory
                cat > ansible-projekte/webserver-beispiel/inventory/hosts.yml << \"HOSTEOF\"
all:
  children:
    webservers:
      hosts:
        localhost:
          ansible_connection: local
      vars:
        ansible_python_interpreter: /usr/bin/python
HOSTEOF
                
                # Test-Playbook
                cat > ansible-projekte/webserver-beispiel/playbooks/test.yml << \"TESTEOF\"
---
- name: Podman Ansible System Test
  hosts: localhost
  connection: local
  gather_facts: yes
  tasks:
    - name: Container-Info anzeigen
      debug:
        msg: |
          🐳 Ansible läuft perfekt in Podman (rootless)!
          Container: {{ ansible_hostname }}
          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}
          Python: {{ ansible_python_version }}
          Ansible: {{ ansible_version.full }}
          User: {{ ansible_user_id }}
          
    - name: Test-Datei erstellen
      copy:
        content: |
          Podman Ansible Test erfolgreich!
          Erstellt am: {{ ansible_date_time.iso8601 }}
          Container: {{ ansible_hostname }}
          Rootless: Ja
        dest: /tmp/podman-ansible-test.txt
        mode: \"0644\"
        
    - name: Test bestätigen
      debug:
        msg: \"✅ Alle Tests erfolgreich! Datei: /tmp/podman-ansible-test.txt\"
TESTEOF
                
                # Container-Info Script
                cat > container-info.sh << \"INFOEOF\"
#!/bin/bash
echo \"=== 🐳 Podman Ansible Container (Rootless) ===\"
echo \"Container: \$(hostname)\"
echo \"User: \$(whoami)\"
echo \"Datum: \$(date)\"
echo \"Ansible: \$(ansible --version | head -1)\"
echo \"Python: \$(python --version)\"
echo
echo \"📁 Projekte:\"
ls -la ansible-projekte/
echo
echo \"🚀 Schnellstart:\"
echo \"  cd ansible-projekte/webserver-beispiel\"
echo \"  ansible-playbook playbooks/test.yml\"
echo
echo \"💡 Podman Vorteile:\"
echo \"  ✅ Rootless (kein sudo)\"
echo \"  ✅ Daemon-frei\"  
echo \"  ✅ Bessere Sicherheit\"
INFOEOF
                chmod +x container-info.sh
                
                # Bashrc anpassen
                echo \"export PS1=\\\"\\[\\033[0;32m\\]\\u@\\h-podman\\[\\033[00m\\]:\\[\\033[0;34m\\]\\w\\[\\033[00m\\]\\$ \\\"\" >> .bashrc
                echo \"cd /home/developer/ansible-projekte\" >> .bashrc
                echo \"./container-info.sh\" >> .bashrc
                echo \"alias ll=\\\"ls -la\\\"\" >> .bashrc
                echo \"alias ap=\\\"ansible-playbook\\\"\" >> .bashrc
                echo \"alias av=\\\"ansible --version\\\"\" >> .bashrc
            '
            
            # SSH-Server starten und Container am Laufen halten
            /usr/sbin/sshd -D &
            tail -f /dev/null
        "; then
        
        sleep 10
        
        log_success "✅ Podman-Container erfolgreich erstellt!"
        
        echo
        log_info "=== Container-Informationen ==="
        echo "• Name: $container_name"
        echo "• SSH-Port: $ssh_port"
        echo "• Hostname: ansible-$(date +%yKW%V)"
        echo "• User: developer / Password: developer"
        echo "• Container-Engine: Podman (rootless)"
        echo "• Sudo erforderlich: NEIN!"
        echo
        
        log_info "=== Zugriff auf Container ==="
        echo "1) Podman Shell: podman exec -it $container_name su - developer"
        echo "2) SSH-Zugang: ssh developer@localhost -p $ssh_port"
        echo "3) Test: podman exec $container_name su - developer -c 'ansible --version'"
        echo
        
        # Sofortiger Test
        log_info "🧪 Führe Ansible-Test aus..."
        if podman exec "$container_name" su - developer -c "
            cd ansible-projekte/webserver-beispiel && 
            ansible-playbook playbooks/test.yml
        "; then
            log_success "✅ Ansible-Test in Podman erfolgreich!"
            
            # Test-Datei prüfen
            if podman exec "$container_name" test -f /tmp/podman-ansible-test.txt; then
                log_success "✅ Test-Datei wurde erstellt"
                log_info "📄 Inhalt:"
                podman exec "$container_name" cat /tmp/podman-ansible-test.txt | sed 's/^/    /'
            fi
        else
            log_warning "⚠️  Ansible-Test hatte Probleme"
        fi
        
        # Login-Script für Podman erstellen
        create_podman_login_script
        
        echo
        read -p "Container-Shell starten? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            log_info "Starte Podman-Container-Shell..."
            podman exec -it "$container_name" su - developer
        else
            echo
            log_success "🎉 Podman-Container einsatzbereit!"
            echo
            log_info "🚀 Schneller Zugang:"
            echo "• podman exec -it $container_name su - developer"
            echo "• ssh developer@localhost -p $ssh_port"
            echo "• ./podman-login.sh (falls erstellt)"
        fi
        
    else
        log_error "Podman-Container-Erstellung fehlgeschlagen"
        return 1
    fi
    
    return 0
}

# Podman Login-Script erstellen
create_podman_login_script() {
    local login_script="./podman-login.sh"
    
    if [ -f "$login_script" ]; then
        return 0
    fi
    
    log_info "📝 Erstelle Podman-Login-Script..."
    
    cat > "$login_script" << 'PODMANEOF'
#!/bin/bash

# Podman Ansible Container Login Helper (Rootless)

get_current_container() {
    echo "$(date +%yKW%V)-docker"
}

quick_shell() {
    local container=$(get_current_container)
    
    if [ "$(podman inspect -f '{{.State.Status}}' "$container" 2>/dev/null)" != "running" ]; then
        echo "Starte Container..."
        podman start "$container"
        sleep 2
    fi
    
    podman exec -it "$container" su - developer
}

case "${1:-}" in
    shell) quick_shell ;;
    info) 
        podman ps -a --filter "name=ansible"
        ;;
    *)
        echo "Podman Ansible Login"
        echo "Verwendung:"
        echo "  $0 shell    # Container-Shell"
        echo "  $0 info     # Container-Info"
        echo
        quick_shell
        ;;
esac
PODMANEOF
    
    chmod +x "$login_script"
    log_success "✅ Podman-Login-Script erstellt: $login_script"
}
create_login_script() {
    local login_script="./login.sh"
    
    # Prüfen ob bereits vorhanden
    if [ -f "$login_script" ]; then
        log_info "📝 Login-Script bereits vorhanden: $login_script"
        return 0
    fi
    
    log_info "📝 Erstelle Login-Script: $login_script"
    
    cat > "$login_script" << 'LOGINEOF'
#!/bin/bash

# =============================================================================
# Ansible Container Login Helper
# =============================================================================
# Automatischer Login in Ansible-Container
# Generiert von: ansible.sh
# =============================================================================

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging-Funktionen
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Banner
show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                   ANSIBLE CONTAINER LOGIN                    ║
║                   Schneller Zugang zu Containern             ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Aktuelle Kalenderwoche ermitteln
get_current_container_name() {
    echo "$(date +%yKW%V)-docker"
}

# Container-SSH-Port ermitteln
get_container_ssh_port() {
    local container_name=$1
    if [[ $container_name =~ [0-9]{2}KW([0-9]+)-docker ]]; then
        local week=${BASH_REMATCH[1]}
        echo $((2280 + 10#$week))
    else
        echo "2222"
    fi
}

# Quick-Login Funktionen
quick_shell() {
    local container=$(get_current_container_name)
    log_info "Verbinde mit $container..."
    
    if [ "$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null)" != "running" ]; then
        log_info "Starte Container..."
        docker start "$container" >/dev/null && sleep 2
    fi
    
    docker exec -it "$container" /bin/bash
}

quick_ssh() {
    local container=$(get_current_container_name)
    local port=$(get_container_ssh_port "$container")
    
    log_info "SSH-Verbindung zu $container (Port: $port)"
    log_info "User: developer | Password: developer"
    
    if [ "$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null)" != "running" ]; then
        docker start "$container" >/dev/null && sleep 3
    fi
    
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$port" developer@localhost
}

show_container_info() {
    local container=$(get_current_container_name)
    local status=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null || echo "not_found")
    local port=$(get_container_ssh_port "$container")
    
    echo -e "${BLUE}=== Aktueller Container ===${NC}"
    echo "📋 Name: $container"
    echo "🔌 Status: $([ "$status" = "running" ] && echo "🟢 Läuft" || echo "🔴 Gestoppt")"
    echo "🌐 SSH-Port: $port"
    echo "👤 User: developer"
    echo "🔑 Password: developer"
    
    if [ "$status" = "running" ]; then
        local hostname=$(docker exec "$container" hostname 2>/dev/null || echo "unknown")
        echo "🖥️  Hostname: $hostname"
        
        if docker exec "$container" command -v ansible >/dev/null 2>&1; then
            local ansible_ver=$(docker exec "$container" ansible --version 2>/dev/null | head -1)
            echo "⚙️  Ansible: $ansible_ver"
        fi
    fi
}

list_containers() {
    echo "Verfügbare Container:"
    docker ps -a --filter "name=-docker" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Keine Container gefunden"
}

# Hauptmenü
main_menu() {
    show_banner
    
    while true; do
        echo
        show_container_info
        echo
        echo "Schnell-Zugang:"
        echo "1) 🐚 Docker Shell (direkter Zugang)"
        echo "2) 🌐 SSH-Login (Port: $(get_container_ssh_port $(get_current_container_name)))"
        echo "3) 📋 Container-Informationen"
        echo "4) 📊 Alle Container anzeigen"
        echo "5) 🚀 Ansible-Test ausführen"
        echo "6) 🔄 Container neustarten"
        echo "7) ❌ Beenden"
        echo
        
        read -p "Wähle Option [1-7]: " choice
        
        case $choice in
            1) quick_shell ;;
            2) quick_ssh ;;
            3) show_container_info; read -p "Drücke Enter..." ;;
            4) list_containers; read -p "Drücke Enter..." ;;
            5) 
                local container=$(get_current_container_name)
                docker exec "$container" /bin/bash -c "
                    cd /home/developer/ansible-projekte/webserver-beispiel && 
                    ansible-playbook playbooks/test.yml
                " 2>/dev/null || log_error "Test fehlgeschlagen"
                read -p "Drücke Enter..."
                ;;
            6)
                local container=$(get_current_container_name)
                log_info "Starte $container neu..."
                docker restart "$container" >/dev/null && log_success "Neustart erfolgreich"
                ;;
            7) exit 0 ;;
            *) log_error "Ungültige Auswahl" ;;
        esac
    done
}

# Kommandozeilen-Parameter
case "${1:-}" in
    -h|--help)
        echo "Ansible Container Login Helper"
        echo "Verwendung:"
        echo "  $0          Interaktives Menü"
        echo "  $0 shell    Direkte Docker-Shell"
        echo "  $0 ssh      SSH-Verbindung"
        echo "  $0 info     Container-Info anzeigen"
        echo "  $0 list     Alle Container auflisten"
        exit 0
        ;;
    shell) quick_shell ;;
    ssh) quick_ssh ;;
    info) show_container_info ;;
    list) list_containers ;;
    *) main_menu ;;
esac
LOGINEOF

    chmod +x "$login_script"
    log_success "✅ Login-Script erstellt: $login_script"
    
    echo
    log_info "🎯 Verwendung des Login-Scripts:"
    echo "• Interaktiv: ./login.sh"
    echo "• Schnell-Shell: ./login.sh shell"
    echo "• SSH-Login: ./login.sh ssh"
    echo "• Container-Info: ./login.sh info"
}

# Automatischer KW-Container mit Vollinstallation
create_weekly_container_auto() {
    local container_name=$(get_current_container_name)
    
    log_info "🚀 Automatische Container-Erstellung + Ansible-Vollinstallation"
    log_info "Container-Name: $container_name"
    log_info "Kalenderwoche: $(date +%V) / Jahr: $(date +%Y)"
    
    # Docker-Setup und Berechtigungen prüfen
    if ! ensure_docker; then
        log_error "Docker-Setup fehlgeschlagen"
        return 1
    fi
    
    # Docker-Command bestimmen (mit oder ohne sudo)
    local DOCKER_CMD="docker"
    if ! docker ps >/dev/null 2>&1; then
        log_info "Verwende sudo für Docker-Befehle..."
        DOCKER_CMD="sudo docker"
        
        # Testen ob sudo-docker funktioniert
        if ! $DOCKER_CMD ps >/dev/null 2>&1; then
            log_error "Auch sudo-docker funktioniert nicht"
            echo
            log_info "Versuche Docker-Service neu zu starten..."
            sudo systemctl restart docker
            sleep 5
            
            if ! $DOCKER_CMD ps >/dev/null 2>&1; then
                log_error "Docker ist nicht funktionsfähig"
                return 1
            fi
        fi
    fi
    
    log_success "✅ Docker einsatzbereit (Command: $DOCKER_CMD)"
    
    # Prüfen ob Container bereits existiert
    if $DOCKER_CMD ps -a --format "{{.Names}}" | grep -q "^${container_name}$"; then
        log_warning "Container '$container_name' existiert bereits!"
        echo
        echo "Optionen:"
        echo "1) Bestehenden Container verwenden"
        echo "2) Container neu erstellen (Daten gehen verloren)"
        echo "3) Abbrechen"
        
        read -p "Wähle [1-3]: " -n 1 -r
        echo
        
        case $REPLY in
            1)
                log_info "Verwende bestehenden Container..."
                if [ "$($DOCKER_CMD inspect -f '{{.State.Running}}' "$container_name" 2>/dev/null)" != "true" ]; then
                    log_info "Starte Container..."
                    $DOCKER_CMD start "$container_name"
                    sleep 3
                fi
                
                log_info "Verbinde mit Container für Ansible-Check..."
                $DOCKER_CMD exec -it "$container_name" /bin/bash -c "
                    echo '=== Ansible Status ==='
                    if command -v ansible >/dev/null 2>&1; then
                        echo '✅ Ansible ist installiert:'
                        ansible --version
                        echo
                        echo '📁 Verfügbare Projekte:'
                        ls -la /home/developer/ansible-projekte/ 2>/dev/null || echo 'Keine Projekte gefunden'
                    else
                        echo '❌ Ansible ist nicht installiert'
                        echo 'Container scheint beschädigt zu sein'
                    fi
                    echo
                    echo '🚀 Schnellstart:'
                    echo '  cd ansible-projekte/webserver-beispiel'
                    echo '  ansible-playbook playbooks/test.yml'
                    echo
                    echo 'Drücke Enter für interaktive Shell...'
                    read
                    exec /bin/bash
                "
                return 0
                ;;
            2)
                log_info "Lösche bestehenden Container..."
                $DOCKER_CMD rm -f "$container_name" 2>/dev/null || true
                ;;
            3)
                log_info "Abgebrochen"
                return 0
                ;;
            *)
                log_error "Ungültige Auswahl"
                return 1
                ;;
        esac
    fi
    
    # Dockerfile für optimierte Installation erstellen
    local setup_dir="/tmp/ansible-container-$(date +%s)"
    mkdir -p "$setup_dir"
    
    log_info "Erstelle optimiertes Docker-Image..."
    
    cat > "$setup_dir/Dockerfile" << 'EOF'
FROM archlinux:latest

# System update und Basis-Pakete
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        base-devel \
        sudo \
        git \
        curl \
        wget \
        vim \
        nano \
        openssh \
        python \
        python-pip \
        python-virtualenv \
        ansible \
        docker \
        yamllint \
        tree \
        htop \
        unzip \
        jq && \
    pacman -Scc --noconfirm

# Benutzer erstellen
RUN useradd -m -G wheel -s /bin/bash developer && \
    echo 'developer:developer' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# SSH-Server konfigurieren
RUN ssh-keygen -A && \
    mkdir -p /run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Python-Module als root installieren (für System-weite Verfügbarkeit)
# Mit expliziter root-user-action um Warnung zu unterdrücken
RUN pip install --root-user-action=ignore --break-system-packages \
        jinja2 \
        paramiko \
        PyYAML \
        cryptography \
        ansible-lint \
        molecule[docker] \
        --no-warn-script-location && \
    echo "# Python-Module erfolgreich installiert" > /tmp/pip-install.log

# Wechsel zu developer user für weitere Setup-Schritte
USER developer
WORKDIR /home/developer

# Python Virtual Environment für User (optional für zusätzliche Module)
RUN python -m venv ~/.ansible-venv && \
    echo "source ~/.ansible-venv/bin/activate" >> ~/.bashrc && \
    echo "export ANSIBLE_PYTHON_INTERPRETER=~/.ansible-venv/bin/python" >> ~/.bashrc

# Ansible-Konfiguration
RUN mkdir -p /home/developer/{ansible-projekte,Downloads,Documents,.ansible,.ssh} && \
    echo '[defaults]' > ~/.ansible/ansible.cfg && \
    echo 'host_key_checking = False' >> ~/.ansible/ansible.cfg && \
    echo 'inventory = ./inventory/hosts.yml' >> ~/.ansible/ansible.cfg && \
    echo 'remote_user = developer' >> ~/.ansible/ansible.cfg && \
    echo 'stdout_callback = yaml' >> ~/.ansible/ansible.cfg && \
    echo 'retry_files_enabled = False' >> ~/.ansible/ansible.cfg && \
    echo 'gathering = smart' >> ~/.ansible/ansible.cfg && \
    echo 'fact_caching = memory' >> ~/.ansible/ansible.cfg && \
    echo '' >> ~/.ansible/ansible.cfg && \
    echo '[privilege_escalation]' >> ~/.ansible/ansible.cfg && \
    echo 'become = True' >> ~/.ansible/ansible.cfg && \
    echo 'become_method = sudo' >> ~/.ansible/ansible.cfg && \
    echo 'become_ask_pass = False' >> ~/.ansible/ansible.cfg && \
    echo '' >> ~/.ansible/ansible.cfg && \
    echo '[ssh_connection]' >> ~/.ansible/ansible.cfg && \
    echo 'ssh_args = -o ControlMaster=auto -o ControlPersist=60s' >> ~/.ansible/ansible.cfg && \
    echo 'pipelining = True' >> ~/.ansible/ansible.cfg

# Beispiel-Projekt erstellen
RUN mkdir -p ansible-projekte/webserver-beispiel/{inventory,playbooks,templates,files,group_vars,host_vars} && \
    echo 'all:' > ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '  children:' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '    webservers:' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '      hosts:' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '        localhost:' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '          ansible_connection: local' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '      vars:' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '        ansible_python_interpreter: /usr/bin/python' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml

# Erweiterte Test-Playbooks erstellen
RUN echo '---' > ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '- name: Ansible System Test' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '  hosts: localhost' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '  connection: local' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '  gather_facts: yes' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '  tasks:' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '    - name: Container-Info anzeigen' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '      debug:' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '        msg: |' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          🚀 Ansible läuft perfekt im Container!' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Container: {{ ansible_hostname }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Python: {{ ansible_python_version }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Ansible: {{ ansible_version.full }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '    - name: Temp-Datei erstellen' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '      copy:' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '        content: |' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Ansible Test erfolgreich!' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Erstellt am: {{ ansible_date_time.iso8601 }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Container: {{ ansible_hostname }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '        dest: /tmp/ansible-test-success.txt' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '        mode: "0644"' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '    - name: Test-Status bestätigen' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '      debug:' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '        msg: "✅ Alle Tests erfolgreich! Datei erstellt: /tmp/ansible-test-success.txt"' >> ansible-projekte/webserver-beispiel/playbooks/test.yml

# Erweiterte Container-Info mit Fehlerbehandlung
RUN echo '#!/bin/bash' > /home/developer/container-info.sh && \
    echo 'set -e' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo 'echo "=== 🐳 Ansible Development Container ==="' >> /home/developer/container-info.sh && \
    echo 'echo "Container: $(hostname)"' >> /home/developer/container-info.sh && \
    echo 'echo "Benutzer: $(whoami)"' >> /home/developer/container-info.sh && \
    echo 'echo "Datum: $(date)"' >> /home/developer/container-info.sh && \
    echo 'echo' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo '# Ansible-Version prüfen' >> /home/developer/container-info.sh && \
    echo 'if command -v ansible >/dev/null 2>&1; then' >> /home/developer/container-info.sh && \
    echo '    echo "✅ Ansible: $(ansible --version | head -1)"' >> /home/developer/container-info.sh && \
    echo 'else' >> /home/developer/container-info.sh && \
    echo '    echo "❌ Ansible nicht gefunden"' >> /home/developer/container-info.sh && \
    echo 'fi' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo '# Python-Version prüfen' >> /home/developer/container-info.sh && \
    echo 'if command -v python >/dev/null 2>&1; then' >> /home/developer/container-info.sh && \
    echo '    echo "✅ Python: $(python --version)"' >> /home/developer/container-info.sh && \
    echo 'else' >> /home/developer/container-info.sh && \
    echo '    echo "❌ Python nicht gefunden"' >> /home/developer/container-info.sh && \
    echo 'fi' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo '# Python-Module prüfen' >> /home/developer/container-info.sh && \
    echo 'echo "🐍 Python-Module:"' >> /home/developer/container-info.sh && \
    echo 'for module in jinja2 paramiko yaml cryptography; do' >> /home/developer/container-info.sh && \
    echo '    if python -c "import $module" 2>/dev/null; then' >> /home/developer/container-info.sh && \
    echo '        echo "  ✅ $module"' >> /home/developer/container-info.sh && \
    echo '    else' >> /home/developer/container-info.sh && \
    echo '        echo "  ❌ $module"' >> /home/developer/container-info.sh && \
    echo '    fi' >> /home/developer/container-info.sh && \
    echo 'done' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo 'echo "📁 Arbeitsverzeichnis: $(pwd)"' >> /home/developer/container-info.sh && \
    echo 'echo' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo '# Projekte anzeigen' >> /home/developer/container-info.sh && \
    echo 'if [ -d ansible-projekte ]; then' >> /home/developer/container-info.sh && \
    echo '    echo "📁 Verfügbare Projekte:"' >> /home/developer/container-info.sh && \
    echo '    ls -la ansible-projekte/ 2>/dev/null || echo "  Keine Projekte gefunden"' >> /home/developer/container-info.sh && \
    echo 'else' >> /home/developer/container-info.sh && \
    echo '    echo "📁 Projekte-Verzeichnis nicht gefunden"' >> /home/developer/container-info.sh && \
    echo 'fi' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo 'echo' >> /home/developer/container-info.sh && \
    echo 'echo "🚀 Schnellstart:"' >> /home/developer/container-info.sh && \
    echo 'echo "  cd ansible-projekte/webserver-beispiel"' >> /home/developer/container-info.sh && \
    echo 'echo "  ansible-playbook playbooks/test.yml"' >> /home/developer/container-info.sh && \
    echo 'echo' >> /home/developer/container-info.sh && \
    echo 'echo "📚 Verfügbare Befehle:"' >> /home/developer/container-info.sh && \
    echo 'echo "  av  - ansible --version"' >> /home/developer/container-info.sh && \
    echo 'echo "  ap  - ansible-playbook"' >> /home/developer/container-info.sh && \
    echo 'echo "  ll  - ls -la"' >> /home/developer/container-info.sh && \
    echo 'echo' >> /home/developer/container-info.sh && \
    chmod +x /home/developer/container-info.sh

# Verbesserte Bashrc mit Fehlerbehandlung
RUN echo '# Ansible Container Bashrc' >> ~/.bashrc && \
    echo 'export PS1="\[\033[0;32m\]\u@\h-ansible\[\033[00m\]:\[\033[0;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Wechsel zu Projekt-Verzeichnis' >> ~/.bashrc && \
    echo 'if [ -d "/home/developer/ansible-projekte" ]; then' >> ~/.bashrc && \
    echo '    cd /home/developer/ansible-projekte' >> ~/.bashrc && \
    echo 'fi' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Container-Info anzeigen (nur bei interaktiver Shell)' >> ~/.bashrc && \
    echo 'if [[ $- == *i* ]] && [ -f "/home/developer/container-info.sh" ]; then' >> ~/.bashrc && \
    echo '    /home/developer/container-info.sh' >> ~/.bashrc && \
    echo 'fi' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Nützliche Aliase' >> ~/.bashrc && \
    echo 'alias ll="ls -la"' >> ~/.bashrc && \
    echo 'alias la="ls -A"' >> ~/.bashrc && \
    echo 'alias l="ls -CF"' >> ~/.bashrc && \
    echo 'alias ap="ansible-playbook"' >> ~/.bashrc && \
    echo 'alias av="ansible --version"' >> ~/.bashrc && \
    echo 'alias ac="ansible-config"' >> ~/.bashrc && \
    echo 'alias ag="ansible-galaxy"' >> ~/.bashrc && \
    echo 'alias al="ansible-lint"' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Ansible-spezifische Umgebungsvariablen' >> ~/.bashrc && \
    echo 'export ANSIBLE_CONFIG=~/.ansible/ansible.cfg' >> ~/.bashrc && \
    echo 'export ANSIBLE_HOST_KEY_CHECKING=False' >> ~/.bashrc && \
    echo 'export ANSIBLE_STDOUT_CALLBACK=yaml' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Hilfe-Funktion' >> ~/.bashrc && \
    echo 'ansible-help() {' >> ~/.bashrc && \
    echo '    echo "=== Ansible Container Hilfe ==="' >> ~/.bashrc && \
    echo '    echo "Befehle:"' >> ~/.bashrc && \
    echo '    echo "  av           - Ansible Version"' >> ~/.bashrc && \
    echo '    echo "  ap <file>    - Playbook ausführen"' >> ~/.bashrc && \
    echo '    echo "  al <file>    - Playbook linten"' >> ~/.bashrc && \
    echo '    echo "  ag           - Ansible Galaxy"' >> ~/.bashrc && \
    echo '    echo ""' >> ~/.bashrc && \
    echo '    echo "Verzeichnisse:"' >> ~/.bashrc && \
    echo '    echo "  ~/ansible-projekte/    - Projekte"' >> ~/.bashrc && \
    echo '    echo "  ~/.ansible/            - Konfiguration"' >> ~/.bashrc && \
    echo '    echo ""' >> ~/.bashrc && \
    echo '    echo "Schnelltest: ap webserver-beispiel/playbooks/test.yml"' >> ~/.bashrc && \
    echo '}' >> ~/.bashrc

# Health-Check für Container erstellen
RUN echo '#!/bin/bash' > /home/developer/health-check.sh && \
    echo 'echo "=== Container Health Check ==="' >> /home/developer/health-check.sh && \
    echo '' >> /home/developer/health-check.sh && \
    echo '# Ansible verfügbar?' >> /home/developer/health-check.sh && \
    echo 'if ansible --version >/dev/null 2>&1; then' >> /home/developer/health-check.sh && \
    echo '    echo "✅ Ansible verfügbar"' >> /home/developer/health-check.sh && \
    echo 'else' >> /home/developer/health-check.sh && \
    echo '    echo "❌ Ansible nicht verfügbar"' >> /home/developer/health-check.sh && \
    echo '    exit 1' >> /home/developer/health-check.sh && \
    echo 'fi' >> /home/developer/health-check.sh && \
    echo '' >> /home/developer/health-check.sh && \
    echo '# Python-Module verfügbar?' >> /home/developer/health-check.sh && \
    echo 'python -c "import ansible, jinja2, paramiko, yaml, cryptography" 2>/dev/null' >> /home/developer/health-check.sh && \
    echo 'if [ $? -eq 0 ]; then' >> /home/developer/health-check.sh && \
    echo '    echo "✅ Python-Module verfügbar"' >> /home/developer/health-check.sh && \
    echo 'else' >> /home/developer/health-check.sh && \
    echo '    echo "❌ Python-Module fehlen"' >> /home/developer/health-check.sh && \
    echo '    exit 1' >> /home/developer/health-check.sh && \
    echo 'fi' >> /home/developer/health-check.sh && \
    echo '' >> /home/developer/health-check.sh && \
    echo '# Test-Playbook verfügbar?' >> /home/developer/health-check.sh && \
    echo 'if [ -f "ansible-projekte/webserver-beispiel/playbooks/test.yml" ]; then' >> /home/developer/health-check.sh && \
    echo '    echo "✅ Test-Playbook verfügbar"' >> /home/developer/health-check.sh && \
    echo 'else' >> /home/developer/health-check.sh && \
    echo '    echo "❌ Test-Playbook fehlt"' >> /home/developer/health-check.sh && \
    echo '    exit 1' >> /home/developer/health-check.sh && \
    echo 'fi' >> /home/developer/health-check.sh && \
    echo '' >> /home/developer/health-check.sh && \
    echo 'echo "✅ Container ist gesund und einsatzbereit!"' >> /home/developer/health-check.sh && \
    chmod +x /home/developer/health-check.sh

CMD ["/bin/bash"]
EOF
    
    # Container bauen (kann etwas dauern)
    log_info "🔨 Baue optimiertes Ansible-Image (dauert ca. 2-3 Minuten)..."
    log_info "💡 Hinweis: pip-Warnungen werden automatisch unterdrückt"
    log_info "⚙️  Docker-Modus: $DOCKER_CMD"
    
    # Build-Logs in temporäre Datei umleiten für bessere Diagnose
    local build_log="/tmp/docker-build-$(date +%s).log"
    
    if $DOCKER_CMD build -t ansible-dev-optimized "$setup_dir/" > "$build_log" 2>&1; then
        log_success "✅ Docker-Image erfolgreich erstellt!"
        
        # Kurze Build-Zusammenfassung anzeigen
        if grep -q "pip install" "$build_log"; then
            log_info "📦 Python-Module erfolgreich installiert (Warnungen unterdrückt)"
        fi
        
        if grep -q "Successfully tagged" "$build_log"; then
            log_info "🏷️  Image-Tag: ansible-dev-optimized"
        fi
    else
        log_error "❌ Docker-Image Build fehlgeschlagen"
        echo
        log_info "=== Build-Fehler-Diagnose ==="
        
        # Spezifische Fehler analysieren
        if grep -q "permission denied" "$build_log"; then
            log_error "Berechtigungsfehler detected:"
            echo "Lösung: Versuche mit sudo-Docker..."
            if [ "$DOCKER_CMD" != "sudo docker" ]; then
                log_info "Versuche Build mit sudo..."
                if sudo docker build -t ansible-dev-optimized "$setup_dir/" > "$build_log" 2>&1; then
                    log_success "✅ Build mit sudo erfolgreich!"
                    DOCKER_CMD="sudo docker"
                else
                    log_error "Auch sudo-Build fehlgeschlagen"
                    tail -15 "$build_log"
                    rm -rf "$setup_dir"
                    return 1
                fi
            fi
        elif grep -q "network" "$build_log"; then
            log_error "Netzwerk-Fehler detected:"
            echo "Lösung: Prüfe Internetverbindung und Docker-Netzwerk"
            echo "        docker network ls"
            echo "        systemctl restart docker"
        elif grep -q "space" "$build_log"; then
            log_error "Speicherplatz-Fehler detected:"
            echo "Lösung: Prüfe verfügbaren Speicherplatz mit 'df -h'"
            echo "        docker system prune -a"
        else
            log_error "Unbekannter Build-Fehler"
        fi
        
        if grep -q "pip.*WARNING" "$build_log"; then
            log_warning "pip-Warnungen gefunden (diese sollten unterdrückt werden):"
            grep "WARNING" "$build_log" | head -3
        fi
        
        echo
        log_info "🔍 Letzte 15 Build-Log-Zeilen:"
        tail -15 "$build_log"
        echo
        log_info "📄 Vollständige Build-Logs: $build_log"
        
        # Cleanup bei Fehler
        rm -rf "$setup_dir"
        return 1
    fi
    
    # Erfolgreiche Build-Logs löschen (um Speicher zu sparen)
    rm -f "$build_log"
    
    # Container starten
    local ssh_port=$((2280 + $(date +%V)))  # Port 2281-2333 basierend auf KW
    log_info "🚀 Starte Container '$container_name'..."
    $DOCKER_CMD run -d \
        --name "$container_name" \
        --hostname "ansible-$(date +%yKW%V)" \
        -p ${ssh_port}:22 \
        -v "${container_name}-projects":/home/developer/ansible-projekte \
        -v "${container_name}-ssh":/home/developer/.ssh \
        -v "${container_name}-home":/home/developer/Documents \
        --privileged \
        ansible-dev-optimized \
        /bin/bash -c "sudo /usr/sbin/sshd -D & tail -f /dev/null"
    
    sleep 5
    
    # SSH-Schlüssel kopieren falls vorhanden
    if [ -f ~/.ssh/id_rsa.pub ]; then
        log_info "📋 Kopiere SSH-Schlüssel..."
        $DOCKER_CMD exec "$container_name" mkdir -p /home/developer/.ssh
        $DOCKER_CMD cp ~/.ssh/id_rsa.pub "$container_name:/home/developer/.ssh/authorized_keys"
        $DOCKER_CMD exec "$container_name" chown -R developer:developer /home/developer/.ssh
        $DOCKER_CMD exec "$container_name" chmod 700 /home/developer/.ssh
        $DOCKER_CMD exec "$container_name" chmod 600 /home/developer/.ssh/authorized_keys
    fi
    
    # Script in Container kopieren
    $DOCKER_CMD cp "$0" "$container_name:/home/developer/installer.sh"
    $DOCKER_CMD exec "$container_name" chown developer:developer /home/developer/installer.sh
    $DOCKER_CMD exec "$container_name" chmod +x /home/developer/installer.sh
    
    # Login-Script erstellen falls nicht vorhanden
    create_login_script
    
    # Cleanup
    rm -rf "$setup_dir"
    
    # Erfolg melden
    log_success "🎉 Container '$container_name' erfolgreich erstellt und Ansible vollständig installiert!"
    
    echo
    log_info "=== Container-Informationen ==="
    echo "• Name: $container_name"
    echo "• SSH-Port: $ssh_port"
    echo "• Hostname: ansible-$(date +%yKW%V)"
    echo "• User: developer / Password: developer"
    echo "• Docker-Modus: $DOCKER_CMD"
    echo "• Persistente Volumes für Projekte und SSH"
    echo
    
    log_info "=== Zugriff auf Container ==="
    echo "1) Login-Script: ./login.sh"
    echo "2) Interaktive Shell: $DOCKER_CMD exec -it $container_name /bin/bash"
    echo "3) SSH-Zugang: ssh developer@localhost -p $ssh_port"
    echo "4) Direkter Test: $DOCKER_CMD exec $container_name ansible --version"
    echo
    
    # Sofortiger Test und Health-Check
    log_info "🧪 Führe Container-Health-Check aus..."
    if $DOCKER_CMD exec "$container_name" /home/developer/health-check.sh; then
        log_success "✅ Health-Check erfolgreich!"
    else
        log_warning "⚠️  Health-Check hatte Probleme"
    fi
    
    echo
    log_info "🚀 Führe erweitertes Ansible-Test aus..."
    if $DOCKER_CMD exec "$container_name" /bin/bash -c "
        cd /home/developer/ansible-projekte/webserver-beispiel && 
        echo '=== Ansible Test Ausführung ===' &&
        ansible-playbook playbooks/test.yml --check --diff &&
        echo &&
        echo '=== Echter Test (ohne --check) ===' &&
        ansible-playbook playbooks/test.yml
    "; then
        log_success "✅ Ansible-Test komplett erfolgreich!"
        
        # Test-Datei prüfen
        if $DOCKER_CMD exec "$container_name" test -f /tmp/ansible-test-success.txt; then
            log_success "✅ Test-Datei wurde erfolgreich erstellt"
            log_info "📄 Inhalt der Test-Datei:"
            $DOCKER_CMD exec "$container_name" cat /tmp/ansible-test-success.txt | sed 's/^/    /'
        fi
    else
        log_warning "⚠️  Ansible-Test hatte Probleme, Container läuft aber"
        
        echo
        log_info "🔍 Diagnose-Informationen:"
        $DOCKER_CMD exec "$container_name" /bin/bash -c "
            echo 'Ansible-Version:' && ansible --version | head -1
            echo 'Python-Version:' && python --version
            echo 'Verfügbare Module:' && python -c 'import sys; print(sys.path)'
        " || log_warning "Diagnose fehlgeschlagen"
    fi
    
    echo
    read -p "Möchtest du eine interaktive Shell im Container starten? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        log_info "Starte interaktive Shell..."
        $DOCKER_CMD exec -it "$container_name" /bin/bash
    else
        echo
        log_success "🎉 Container erfolgreich erstellt!"
        echo
        log_info "🚀 Schneller Zugang zum Container:"
        echo "• ./login.sh          # Interaktives Login-Menü"
        echo "• ./login.sh shell    # Direkte Docker-Shell"
        echo "• ./login.sh ssh      # SSH-Verbindung"
        echo
        log_info "📋 Container-Details:"
        echo "• Name: $container_name"
        echo "• SSH: ssh developer@localhost -p $ssh_port"
        echo "• Password: developer"
    fi
    
    return 0
}
    
    # Prüfen ob Container bereits existiert
    if $DOCKER_CMD ps -a --format "{{.Names}}" | grep -q "^${container_name}$"; then
        log_warning "Container '$container_name' existiert bereits!"
        echo
        echo "Optionen:"
        echo "1) Bestehenden Container verwenden"
        echo "2) Container neu erstellen (Daten gehen verloren)"
        echo "3) Abbrechen"
        
        read -p "Wähle [1-3]: " -n 1 -r
        echo
        
        case $REPLY in
            1)
                log_info "Verwende bestehenden Container..."
                if [ "$($DOCKER_CMD inspect -f '{{.State.Running}}' "$container_name")" != "true" ]; then
                    $DOCKER_CMD start "$container_name"
                fi
                
                log_info "Verbinde mit Container für Ansible-Check..."
                $DOCKER_CMD exec -it "$container_name" /bin/bash -c "
                    echo '=== Ansible Status ==='
                    if command -v ansible >/dev/null 2>&1; then
                        echo '✅ Ansible ist installiert:'
                        ansible --version
                        echo
                        echo '📁 Verfügbare Projekte:'
                        ls -la /home/developer/ansible-projekte/ 2>/dev/null || echo 'Keine Projekte gefunden'
                    else
                        echo '❌ Ansible ist nicht installiert'
                        echo 'Führe Installation aus...'
                        /home/developer/ansible.sh <<< '2'
                    fi
                    echo
                    echo 'Drücke Enter für interaktive Shell...'
                    read
                    exec /bin/bash
                "
                return 0
                ;;
            2)
                log_info "Lösche bestehenden Container..."
                $DOCKER_CMD rm -f "$container_name" 2>/dev/null || true
                ;;
            3)
                log_info "Abgebrochen"
                return 0
                ;;
            *)
                log_error "Ungültige Auswahl"
                return 1
                ;;
        esac
    fi
    
    # Dockerfile für optimierte Installation erstellen
    local setup_dir="/tmp/ansible-container-$(date +%s)"
    mkdir -p "$setup_dir"
    
    log_info "Erstelle optimiertes Docker-Image..."
    
    cat > "$setup_dir/Dockerfile" << 'EOF'
FROM archlinux:latest

# System update und Basis-Pakete
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        base-devel \
        sudo \
        git \
        curl \
        wget \
        vim \
        nano \
        openssh \
        python \
        python-pip \
        python-virtualenv \
        ansible \
        docker \
        yamllint \
        tree \
        htop \
        unzip \
        jq && \
    pacman -Scc --noconfirm

# Benutzer erstellen
RUN useradd -m -G wheel -s /bin/bash developer && \
    echo 'developer:developer' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# SSH-Server konfigurieren
RUN ssh-keygen -A && \
    mkdir -p /run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Python-Module als root installieren (für System-weite Verfügbarkeit)
# Mit expliziter root-user-action um Warnung zu unterdrücken
RUN pip install --root-user-action=ignore --break-system-packages \
        jinja2 \
        paramiko \
        PyYAML \
        cryptography \
        ansible-lint \
        molecule[docker] \
        --no-warn-script-location && \
    echo "# Python-Module erfolgreich installiert" > /tmp/pip-install.log

# Wechsel zu developer user für weitere Setup-Schritte
USER developer
WORKDIR /home/developer

# Python Virtual Environment für User (optional für zusätzliche Module)
RUN python -m venv ~/.ansible-venv && \
    echo "source ~/.ansible-venv/bin/activate" >> ~/.bashrc && \
    echo "export ANSIBLE_PYTHON_INTERPRETER=~/.ansible-venv/bin/python" >> ~/.bashrc

# Ansible-Konfiguration
RUN mkdir -p /home/developer/{ansible-projekte,Downloads,Documents,.ansible,.ssh} && \
    echo '[defaults]' > ~/.ansible/ansible.cfg && \
    echo 'host_key_checking = False' >> ~/.ansible/ansible.cfg && \
    echo 'inventory = ./inventory/hosts.yml' >> ~/.ansible/ansible.cfg && \
    echo 'remote_user = developer' >> ~/.ansible/ansible.cfg && \
    echo 'stdout_callback = yaml' >> ~/.ansible/ansible.cfg && \
    echo 'retry_files_enabled = False' >> ~/.ansible/ansible.cfg && \
    echo 'gathering = smart' >> ~/.ansible/ansible.cfg && \
    echo 'fact_caching = memory' >> ~/.ansible/ansible.cfg && \
    echo '' >> ~/.ansible/ansible.cfg && \
    echo '[privilege_escalation]' >> ~/.ansible/ansible.cfg && \
    echo 'become = True' >> ~/.ansible/ansible.cfg && \
    echo 'become_method = sudo' >> ~/.ansible/ansible.cfg && \
    echo 'become_ask_pass = False' >> ~/.ansible/ansible.cfg && \
    echo '' >> ~/.ansible/ansible.cfg && \
    echo '[ssh_connection]' >> ~/.ansible/ansible.cfg && \
    echo 'ssh_args = -o ControlMaster=auto -o ControlPersist=60s' >> ~/.ansible/ansible.cfg && \
    echo 'pipelining = True' >> ~/.ansible/ansible.cfg

# Beispiel-Projekt erstellen
RUN mkdir -p ansible-projekte/webserver-beispiel/{inventory,playbooks,templates,files,group_vars,host_vars} && \
    echo 'all:' > ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '  children:' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '    webservers:' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '      hosts:' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '        localhost:' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '          ansible_connection: local' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '      vars:' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml && \
    echo '        ansible_python_interpreter: /usr/bin/python' >> ansible-projekte/webserver-beispiel/inventory/hosts.yml

# Erweiterte Test-Playbooks erstellen
RUN echo '---' > ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '- name: Ansible System Test' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '  hosts: localhost' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '  connection: local' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '  gather_facts: yes' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '  tasks:' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '    - name: Container-Info anzeigen' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '      debug:' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '        msg: |' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          🚀 Ansible läuft perfekt im Container!' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Container: {{ ansible_hostname }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          OS: {{ ansible_distribution }} {{ ansible_distribution_version }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Python: {{ ansible_python_version }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Ansible: {{ ansible_version.full }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '    - name: Temp-Datei erstellen' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '      copy:' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '        content: |' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Ansible Test erfolgreich!' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Erstellt am: {{ ansible_date_time.iso8601 }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '          Container: {{ ansible_hostname }}' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '        dest: /tmp/ansible-test-success.txt' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '        mode: "0644"' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '    - name: Test-Status bestätigen' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '      debug:' >> ansible-projekte/webserver-beispiel/playbooks/test.yml && \
    echo '        msg: "✅ Alle Tests erfolgreich! Datei erstellt: /tmp/ansible-test-success.txt"' >> ansible-projekte/webserver-beispiel/playbooks/test.yml

# Erweiterte Container-Info mit Fehlerbehandlung
RUN echo '#!/bin/bash' > /home/developer/container-info.sh && \
    echo 'set -e' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo 'echo "=== 🐳 Ansible Development Container ==="' >> /home/developer/container-info.sh && \
    echo 'echo "Container: $(hostname)"' >> /home/developer/container-info.sh && \
    echo 'echo "Benutzer: $(whoami)"' >> /home/developer/container-info.sh && \
    echo 'echo "Datum: $(date)"' >> /home/developer/container-info.sh && \
    echo 'echo' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo '# Ansible-Version prüfen' >> /home/developer/container-info.sh && \
    echo 'if command -v ansible >/dev/null 2>&1; then' >> /home/developer/container-info.sh && \
    echo '    echo "✅ Ansible: $(ansible --version | head -1)"' >> /home/developer/container-info.sh && \
    echo 'else' >> /home/developer/container-info.sh && \
    echo '    echo "❌ Ansible nicht gefunden"' >> /home/developer/container-info.sh && \
    echo 'fi' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo '# Python-Version prüfen' >> /home/developer/container-info.sh && \
    echo 'if command -v python >/dev/null 2>&1; then' >> /home/developer/container-info.sh && \
    echo '    echo "✅ Python: $(python --version)"' >> /home/developer/container-info.sh && \
    echo 'else' >> /home/developer/container-info.sh && \
    echo '    echo "❌ Python nicht gefunden"' >> /home/developer/container-info.sh && \
    echo 'fi' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo '# Python-Module prüfen' >> /home/developer/container-info.sh && \
    echo 'echo "🐍 Python-Module:"' >> /home/developer/container-info.sh && \
    echo 'for module in jinja2 paramiko yaml cryptography; do' >> /home/developer/container-info.sh && \
    echo '    if python -c "import $module" 2>/dev/null; then' >> /home/developer/container-info.sh && \
    echo '        echo "  ✅ $module"' >> /home/developer/container-info.sh && \
    echo '    else' >> /home/developer/container-info.sh && \
    echo '        echo "  ❌ $module"' >> /home/developer/container-info.sh && \
    echo '    fi' >> /home/developer/container-info.sh && \
    echo 'done' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo 'echo "📁 Arbeitsverzeichnis: $(pwd)"' >> /home/developer/container-info.sh && \
    echo 'echo' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo '# Projekte anzeigen' >> /home/developer/container-info.sh && \
    echo 'if [ -d ansible-projekte ]; then' >> /home/developer/container-info.sh && \
    echo '    echo "📁 Verfügbare Projekte:"' >> /home/developer/container-info.sh && \
    echo '    ls -la ansible-projekte/ 2>/dev/null || echo "  Keine Projekte gefunden"' >> /home/developer/container-info.sh && \
    echo 'else' >> /home/developer/container-info.sh && \
    echo '    echo "📁 Projekte-Verzeichnis nicht gefunden"' >> /home/developer/container-info.sh && \
    echo 'fi' >> /home/developer/container-info.sh && \
    echo '' >> /home/developer/container-info.sh && \
    echo 'echo' >> /home/developer/container-info.sh && \
    echo 'echo "🚀 Schnellstart:"' >> /home/developer/container-info.sh && \
    echo 'echo "  cd ansible-projekte/webserver-beispiel"' >> /home/developer/container-info.sh && \
    echo 'echo "  ansible-playbook playbooks/test.yml"' >> /home/developer/container-info.sh && \
    echo 'echo' >> /home/developer/container-info.sh && \
    echo 'echo "📚 Verfügbare Befehle:"' >> /home/developer/container-info.sh && \
    echo 'echo "  av  - ansible --version"' >> /home/developer/container-info.sh && \
    echo 'echo "  ap  - ansible-playbook"' >> /home/developer/container-info.sh && \
    echo 'echo "  ll  - ls -la"' >> /home/developer/container-info.sh && \
    echo 'echo' >> /home/developer/container-info.sh && \
    chmod +x /home/developer/container-info.sh

# Verbesserte Bashrc mit Fehlerbehandlung
RUN echo '# Ansible Container Bashrc' >> ~/.bashrc && \
    echo 'export PS1="\[\033[0;32m\]\u@\h-ansible\[\033[00m\]:\[\033[0;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Wechsel zu Projekt-Verzeichnis' >> ~/.bashrc && \
    echo 'if [ -d "/home/developer/ansible-projekte" ]; then' >> ~/.bashrc && \
    echo '    cd /home/developer/ansible-projekte' >> ~/.bashrc && \
    echo 'fi' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Container-Info anzeigen (nur bei interaktiver Shell)' >> ~/.bashrc && \
    echo 'if [[ $- == *i* ]] && [ -f "/home/developer/container-info.sh" ]; then' >> ~/.bashrc && \
    echo '    /home/developer/container-info.sh' >> ~/.bashrc && \
    echo 'fi' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Nützliche Aliase' >> ~/.bashrc && \
    echo 'alias ll="ls -la"' >> ~/.bashrc && \
    echo 'alias la="ls -A"' >> ~/.bashrc && \
    echo 'alias l="ls -CF"' >> ~/.bashrc && \
    echo 'alias ap="ansible-playbook"' >> ~/.bashrc && \
    echo 'alias av="ansible --version"' >> ~/.bashrc && \
    echo 'alias ac="ansible-config"' >> ~/.bashrc && \
    echo 'alias ag="ansible-galaxy"' >> ~/.bashrc && \
    echo 'alias al="ansible-lint"' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Ansible-spezifische Umgebungsvariablen' >> ~/.bashrc && \
    echo 'export ANSIBLE_CONFIG=~/.ansible/ansible.cfg' >> ~/.bashrc && \
    echo 'export ANSIBLE_HOST_KEY_CHECKING=False' >> ~/.bashrc && \
    echo 'export ANSIBLE_STDOUT_CALLBACK=yaml' >> ~/.bashrc && \
    echo '' >> ~/.bashrc && \
    echo '# Hilfe-Funktion' >> ~/.bashrc && \
    echo 'ansible-help() {' >> ~/.bashrc && \
    echo '    echo "=== Ansible Container Hilfe ==="' >> ~/.bashrc && \
    echo '    echo "Befehle:"' >> ~/.bashrc && \
    echo '    echo "  av           - Ansible Version"' >> ~/.bashrc && \
    echo '    echo "  ap <file>    - Playbook ausführen"' >> ~/.bashrc && \
    echo '    echo "  al <file>    - Playbook linten"' >> ~/.bashrc && \
    echo '    echo "  ag           - Ansible Galaxy"' >> ~/.bashrc && \
    echo '    echo ""' >> ~/.bashrc && \
    echo '    echo "Verzeichnisse:"' >> ~/.bashrc && \
    echo '    echo "  ~/ansible-projekte/    - Projekte"' >> ~/.bashrc && \
    echo '    echo "  ~/.ansible/            - Konfiguration"' >> ~/.bashrc && \
    echo '    echo ""' >> ~/.bashrc && \
    echo '    echo "Schnelltest: ap webserver-beispiel/playbooks/test.yml"' >> ~/.bashrc && \
    echo '}' >> ~/.bashrc

# Health-Check für Container erstellen
RUN echo '#!/bin/bash' > /home/developer/health-check.sh && \
    echo 'echo "=== Container Health Check ==="' >> /home/developer/health-check.sh && \
    echo '' >> /home/developer/health-check.sh && \
    echo '# Ansible verfügbar?' >> /home/developer/health-check.sh && \
    echo 'if ansible --version >/dev/null 2>&1; then' >> /home/developer/health-check.sh && \
    echo '    echo "✅ Ansible verfügbar"' >> /home/developer/health-check.sh && \
    echo 'else' >> /home/developer/health-check.sh && \
    echo '    echo "❌ Ansible nicht verfügbar"' >> /home/developer/health-check.sh && \
    echo '    exit 1' >> /home/developer/health-check.sh && \
    echo 'fi' >> /home/developer/health-check.sh && \
    echo '' >> /home/developer/health-check.sh && \
    echo '# Python-Module verfügbar?' >> /home/developer/health-check.sh && \
    echo 'python -c "import ansible, jinja2, paramiko, yaml, cryptography" 2>/dev/null' >> /home/developer/health-check.sh && \
    echo 'if [ $? -eq 0 ]; then' >> /home/developer/health-check.sh && \
    echo '    echo "✅ Python-Module verfügbar"' >> /home/developer/health-check.sh && \
    echo 'else' >> /home/developer/health-check.sh && \
    echo '    echo "❌ Python-Module fehlen"' >> /home/developer/health-check.sh && \
    echo '    exit 1' >> /home/developer/health-check.sh && \
    echo 'fi' >> /home/developer/health-check.sh && \
    echo '' >> /home/developer/health-check.sh && \
    echo '# Test-Playbook verfügbar?' >> /home/developer/health-check.sh && \
    echo 'if [ -f "ansible-projekte/webserver-beispiel/playbooks/test.yml" ]; then' >> /home/developer/health-check.sh && \
    echo '    echo "✅ Test-Playbook verfügbar"' >> /home/developer/health-check.sh && \
    echo 'else' >> /home/developer/health-check.sh && \
    echo '    echo "❌ Test-Playbook fehlt"' >> /home/developer/health-check.sh && \
    echo '    exit 1' >> /home/developer/health-check.sh && \
    echo 'fi' >> /home/developer/health-check.sh && \
    echo '' >> /home/developer/health-check.sh && \
    echo 'echo "✅ Container ist gesund und einsatzbereit!"' >> /home/developer/health-check.sh && \
    chmod +x /home/developer/health-check.sh

CMD ["/bin/bash"]
EOF
    
    # Container bauen (kann etwas dauern)
    log_info "🔨 Baue optimiertes Ansible-Image (dauert ca. 2-3 Minuten)..."
    log_info "💡 Hinweis: pip-Warnungen werden automatisch unterdrückt"
    
    # Build-Logs in temporäre Datei umleiten für bessere Diagnose
    local build_log="/tmp/docker-build-$(date +%s).log"
    
    if $DOCKER_CMD build -t ansible-dev-optimized "$setup_dir/" > "$build_log" 2>&1; then
        log_success "✅ Docker-Image erfolgreich erstellt!"
        
        # Kurze Build-Zusammenfassung anzeigen
        if grep -q "pip install" "$build_log"; then
            log_info "📦 Python-Module erfolgreich installiert (Warnungen unterdrückt)"
        fi
        
        if grep -q "Successfully tagged" "$build_log"; then
            log_info "🏷️  Image-Tag: ansible-dev-optimized"
        fi
    else
        log_error "❌ Docker-Image Build fehlgeschlagen"
        echo
        log_info "=== Build-Fehler-Diagnose ==="
        
        # Spezifische Fehler analysieren
        if grep -q "permission denied" "$build_log"; then
            log_error "Berechtigungsfehler detected:"
            echo "Lösung: Führe das Script als normaler User aus (nicht root)"
            echo "        Stelle sicher, dass Docker-Berechtigungen korrekt sind"
        fi
        
        if grep -q "network" "$build_log"; then
            log_error "Netzwerk-Fehler detected:"
            echo "Lösung: Prüfe Internetverbindung und Docker-Netzwerk"
        fi
        
        if grep -q "space" "$build_log"; then
            log_error "Speicherplatz-Fehler detected:"
            echo "Lösung: Prüfe verfügbaren Speicherplatz mit 'df -h'"
        fi
        
        if grep -q "pip.*WARNING" "$build_log"; then
            log_warning "pip-Warnungen gefunden (diese sind normal und werden korrigiert):"
            grep "WARNING" "$build_log" | head -3
        fi
        
        echo
        log_info "🔍 Letzte 15 Build-Log-Zeilen:"
        tail -15 "$build_log"
        echo
        log_info "📄 Vollständige Build-Logs: $build_log"
        
        # Cleanup bei Fehler
        rm -rf "$setup_dir"
        return 1
    fi
    
    # Erfolgreiche Build-Logs löschen (um Speicher zu sparen)
    rm -f "$build_log"
    
    # Container starten
    local ssh_port=$((2280 + $(date +%V)))  # Port 2281-2333 basierend auf KW
    log_info "🚀 Starte Container '$container_name'..."
    $DOCKER_CMD run -d \
        --name "$container_name" \
        --hostname "ansible-$(date +%yKW%V)" \
        -p ${ssh_port}:22 \
        -v "${container_name}-projects":/home/developer/ansible-projekte \
        -v "${container_name}-ssh":/home/developer/.ssh \
        -v "${container_name}-home":/home/developer/Documents \
        --privileged \
        ansible-dev-optimized \
        /bin/bash -c "sudo /usr/sbin/sshd -D & tail -f /dev/null"
    
    sleep 5
    
    # SSH-Schlüssel kopieren falls vorhanden
    if [ -f ~/.ssh/id_rsa.pub ]; then
        log_info "📋 Kopiere SSH-Schlüssel..."
        $DOCKER_CMD exec "$container_name" mkdir -p /home/developer/.ssh
        $DOCKER_CMD cp ~/.ssh/id_rsa.pub "$container_name:/home/developer/.ssh/authorized_keys"
        $DOCKER_CMD exec "$container_name" chown -R developer:developer /home/developer/.ssh
        $DOCKER_CMD exec "$container_name" chmod 700 /home/developer/.ssh
        $DOCKER_CMD exec "$container_name" chmod 600 /home/developer/.ssh/authorized_keys
    fi
    
    # Script in Container kopieren
    $DOCKER_CMD cp "$0" "$container_name:/home/developer/installer.sh"
    $DOCKER_CMD exec "$container_name" chown developer:developer /home/developer/installer.sh
    $DOCKER_CMD exec "$container_name" chmod +x /home/developer/installer.sh
    
    # Login-Script erstellen falls nicht vorhanden
    create_login_script
    
# Login-Script erstellen
create_login_script() {
    local login_script="./login.sh"
    
    # Prüfen ob bereits vorhanden
    if [ -f "$login_script" ]; then
        log_info "📝 Login-Script bereits vorhanden: $login_script"
        return 0
    fi
    
    log_info "📝 Erstelle Login-Script: $login_script"
    
    cat > "$login_script" << 'LOGINEOF'
#!/bin/bash

# =============================================================================
# Ansible Container Login Helper
# =============================================================================
# Automatischer Login in Ansible-Container
# Generiert von: ansible.sh
# =============================================================================

set -e

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging-Funktionen
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Banner
show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                   ANSIBLE CONTAINER LOGIN                    ║
║                   Schneller Zugang zu Containern             ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Aktuelle Kalenderwoche ermitteln
get_current_container_name() {
    echo "$(date +%yKW%V)-docker"
}

# Container-SSH-Port ermitteln
get_container_ssh_port() {
    local container_name=$1
    if [[ $container_name =~ [0-9]{2}KW([0-9]+)-docker ]]; then
        local week=${BASH_REMATCH[1]}
        echo $((2280 + 10#$week))
    else
        echo "2222"
    fi
}

# Quick-Login Funktionen
quick_shell() {
    local container=$(get_current_container_name)
    log_info "Verbinde mit $container..."
    
    if [ "$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null)" != "running" ]; then
        log_info "Starte Container..."
        docker start "$container" >/dev/null && sleep 2
    fi
    
    docker exec -it "$container" /bin/bash
}

quick_ssh() {
    local container=$(get_current_container_name)
    local port=$(get_container_ssh_port "$container")
    
    log_info "SSH-Verbindung zu $container (Port: $port)"
    log_info "User: developer | Password: developer"
    
    if [ "$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null)" != "running" ]; then
        docker start "$container" >/dev/null && sleep 3
    fi
    
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$port" developer@localhost
}

show_container_info() {
    local container=$(get_current_container_name)
    local status=$(docker inspect -f '{{.State.Status}}' "$container" 2>/dev/null || echo "not_found")
    local port=$(get_container_ssh_port "$container")
    
    echo -e "${BLUE}=== Aktueller Container ===${NC}"
    echo "📋 Name: $container"
    echo "🔌 Status: $([ "$status" = "running" ] && echo "🟢 Läuft" || echo "🔴 Gestoppt")"
    echo "🌐 SSH-Port: $port"
    echo "👤 User: developer"
    echo "🔑 Password: developer"
    
    if [ "$status" = "running" ]; then
        local hostname=$(docker exec "$container" hostname 2>/dev/null || echo "unknown")
        echo "🖥️  Hostname: $hostname"
        
        if docker exec "$container" command -v ansible >/dev/null 2>&1; then
            local ansible_ver=$(docker exec "$container" ansible --version 2>/dev/null | head -1)
            echo "⚙️  Ansible: $ansible_ver"
        fi
    fi
}

list_containers() {
    echo "Verfügbare Container:"
    docker ps -a --filter "name=-docker" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "Keine Container gefunden"
}

# Hauptmenü
main_menu() {
    show_banner
    
    while true; do
        echo
        show_container_info
        echo
        echo "Schnell-Zugang:"
        echo "1) 🐚 Docker Shell (direkter Zugang)"
        echo "2) 🌐 SSH-Login (Port: $(get_container_ssh_port $(get_current_container_name)))"
        echo "3) 📋 Container-Informationen"
        echo "4) 📊 Alle Container anzeigen"
        echo "5) 🚀 Ansible-Test ausführen"
        echo "6) 🔄 Container neustarten"
        echo "7) ❌ Beenden"
        echo
        
        read -p "Wähle Option [1-7]: " choice
        
        case $choice in
            1) quick_shell ;;
            2) quick_ssh ;;
            3) show_container_info; read -p "Drücke Enter..." ;;
            4) list_containers; read -p "Drücke Enter..." ;;
            5) 
                local container=$(get_current_container_name)
                docker exec "$container" /bin/bash -c "
                    cd /home/developer/ansible-projekte/webserver-beispiel && 
                    ansible-playbook playbooks/test.yml
                " 2>/dev/null || log_error "Test fehlgeschlagen"
                read -p "Drücke Enter..."
                ;;
            6)
                local container=$(get_current_container_name)
                log_info "Starte $container neu..."
                docker restart "$container" >/dev/null && log_success "Neustart erfolgreich"
                ;;
            7) exit 0 ;;
            *) log_error "Ungültige Auswahl" ;;
        esac
    done
}

# Kommandozeilen-Parameter
case "${1:-}" in
    -h|--help)
        echo "Ansible Container Login Helper"
        echo "Verwendung:"
        echo "  $0          Interaktives Menü"
        echo "  $0 shell    Direkte Docker-Shell"
        echo "  $0 ssh      SSH-Verbindung"
        echo "  $0 info     Container-Info anzeigen"
        echo "  $0 list     Alle Container auflisten"
        exit 0
        ;;
    shell) quick_shell ;;
    ssh) quick_ssh ;;
    info) show_container_info ;;
    list) list_containers ;;
    *) main_menu ;;
esac
LOGINEOF

    chmod +x "$login_script"
    log_success "✅ Login-Script erstellt: $login_script"
    
    echo
    log_info "🎯 Verwendung des Login-Scripts:"
    echo "• Interaktiv: ./login.sh"
    echo "• Schnell-Shell: ./login.sh shell"
    echo "• SSH-Login: ./login.sh ssh"
    echo "• Container-Info: ./login.sh info"
}
    
    # Erfolg melden
    log_success "🎉 Container '$container_name' erfolgreich erstellt und Ansible vollständig installiert!"
    
    echo
    log_info "=== Container-Informationen ==="
    echo "• Name: $container_name"
    echo "• SSH-Port: $ssh_port"
    echo "• Hostname: ansible-$(date +%yKW%V)"
    echo "• User: developer / Password: developer"
    echo "• Persistente Volumes für Projekte und SSH"
    echo
    
    log_info "=== Zugriff auf Container ==="
    echo "1) Interaktive Shell: $DOCKER_CMD exec -it $container_name /bin/bash"
    echo "2) SSH-Zugang: ssh developer@localhost -p $ssh_port"
    echo "3) Direkter Test: $DOCKER_CMD exec $container_name ansible --version"
    echo
    
    # Sofortiger Test und Health-Check
    log_info "🧪 Führe Container-Health-Check aus..."
    if $DOCKER_CMD exec "$container_name" /home/developer/health-check.sh; then
        log_success "✅ Health-Check erfolgreich!"
    else
        log_warning "⚠️  Health-Check hatte Probleme"
    fi
    
    echo
    log_info "🚀 Führe erweitertes Ansible-Test aus..."
    if $DOCKER_CMD exec "$container_name" /bin/bash -c "
        cd /home/developer/ansible-projekte/webserver-beispiel && 
        echo '=== Ansible Test Ausführung ===' &&
        ansible-playbook playbooks/test.yml --check --diff &&
        echo &&
        echo '=== Echter Test (ohne --check) ===' &&
        ansible-playbook playbooks/test.yml
    "; then
        log_success "✅ Ansible-Test komplett erfolgreich!"
        
        # Test-Datei prüfen
        if $DOCKER_CMD exec "$container_name" test -f /tmp/ansible-test-success.txt; then
            log_success "✅ Test-Datei wurde erfolgreich erstellt"
            log_info "📄 Inhalt der Test-Datei:"
            $DOCKER_CMD exec "$container_name" cat /tmp/ansible-test-success.txt | sed 's/^/    /'
        fi
    else
        log_warning "⚠️  Ansible-Test hatte Probleme, Container läuft aber"
        
        echo
        log_info "🔍 Diagnose-Informationen:"
        $DOCKER_CMD exec "$container_name" /bin/bash -c "
            echo 'Ansible-Version:' && ansible --version | head -1
            echo 'Python-Version:' && python --version
            echo 'Verfügbare Module:' && python -c 'import sys; print(sys.path)'
        " || log_warning "Diagnose fehlgeschlagen"
    fi
    
    echo
    read -p "Möchtest du eine interaktive Shell im Container starten? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        log_info "Starte interaktive Shell..."
        $DOCKER_CMD exec -it "$container_name" /bin/bash
    else
        echo
        log_success "🎉 Container erfolgreich erstellt!"
        echo
        log_info "🚀 Schneller Zugang zum Container:"
        echo "• ./login.sh          # Interaktives Login-Menü"
        echo "• ./login.sh shell    # Direkte Docker-Shell"
        echo "• ./login.sh ssh      # SSH-Verbindung"
        echo
        log_info "📋 Container-Details:"
        echo "• Name: $container_name"
        echo "• SSH: ssh developer@localhost -p $ssh_port"
        echo "• Password: developer"
    fi
    
    return 0
}

# Manjaro/Arch Container für Ansible-Installation starten
run_in_docker_container() {
    log_info "Bereite Docker-Container für Ansible-Installation vor..."
    
    # Docker prüfen
    if ! ensure_docker; then
        log_error "Docker-Setup fehlgeschlagen"
        return 1
    fi
    
    # Container-Name
    local container_name="ansible-manjaro-dev"
    local container_exists=false
    
    # Prüfen ob Container bereits existiert
    if docker ps -a --format "table {{.Names}}" | grep -q "^${container_name}$"; then
        container_exists=true
        log_info "Container $container_name existiert bereits"
        
        echo "Was möchtest du tun?"
        echo "1) Bestehenden Container verwenden"
        echo "2) Container neu erstellen (Daten gehen verloren)"
        echo "3) Abbrechen"
        
        read -p "Wähle [1-3]: " -n 1 -r
        echo
        
        case $REPLY in
            1)
                log_info "Verwende bestehenden Container..."
                ;;
            2)
                log_info "Lösche und erstelle Container neu..."
                docker rm -f "$container_name" 2>/dev/null || true
                container_exists=false
                ;;
            3)
                log_info "Abgebrochen"
                return 0
                ;;
            *)
                log_error "Ungültige Auswahl"
                return 1
                ;;
        esac
    fi
    
    # Container erstellen falls nicht vorhanden
    if [ "$container_exists" = false ]; then
        log_info "Erstelle neuen Container mit Manjaro-ähnlichem Environment..."
        
        # Arbeitsverzeichnis erstellen
        mkdir -p /tmp/ansible-container-setup
        
        # Dockerfile erstellen
        cat > /tmp/ansible-container-setup/Dockerfile << 'EOF'
FROM archlinux:latest

# System aktualisieren und Basis-Pakete installieren
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
        base-devel \
        sudo \
        git \
        curl \
        wget \
        vim \
        nano \
        openssh \
        python \
        python-pip && \
    pacman -Scc --noconfirm

# Benutzer erstellen
RUN useradd -m -G wheel -s /bin/bash developer && \
    echo 'developer:developer' | chpasswd && \
    echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# SSH-Server konfigurieren
RUN ssh-keygen -A && \
    mkdir -p /run/sshd

# Arbeitsverzeichnis
WORKDIR /home/developer
USER developer

# Home-Verzeichnis setup
RUN mkdir -p /home/developer/{Downloads,Documents,ansible-projekte}

CMD ["/bin/bash"]
EOF
        
        # Container bauen
        log_info "Baue Docker-Image (das kann etwas dauern)..."
        if ! docker build -t ansible-manjaro-dev /tmp/ansible-container-setup/; then
            log_error "Docker-Image Build fehlgeschlagen"
            return 1
        fi
        
        # Container starten
        log_info "Starte Container..."
        docker run -d \
            --name "$container_name" \
            --hostname ansible-dev \
            -p 2223:22 \
            -v "$(pwd)":/host-scripts:ro \
            -v ansible-projects:/home/developer/ansible-projekte \
            -v ansible-ssh:/home/developer/.ssh \
            --privileged \
            ansible-manjaro-dev \
            /bin/bash -c "sudo /usr/sbin/sshd -D & tail -f /dev/null"
        
        sleep 3
        
        # Script in Container kopieren
        docker cp "$0" "$container_name:/home/developer/ansible.sh"
        docker exec "$container_name" chown developer:developer /home/developer/ansible.sh
        docker exec "$container_name" chmod +x /home/developer/ansible.sh
        
        log_success "Container '$container_name' wurde erstellt und gestartet"
    else
        # Bestehenden Container starten falls gestoppt
        if [ "$(docker inspect -f '{{.State.Running}}' "$container_name")" != "true" ]; then
            log_info "Starte bestehenden Container..."
            docker start "$container_name"
        fi
    fi
    
    # Informationen anzeigen
    echo
    log_success "Docker-Container ist bereit!"
    echo
    log_info "Container-Informationen:"
    echo "• Name: $container_name"
    echo "• SSH-Port: 2223"
    echo "• User: developer"
    echo "• Password: developer"
    echo
    log_info "Verfügbare Aktionen:"
    echo "1) Interaktive Shell starten"
    echo "2) Ansible-Installation im Container ausführen"
    echo "3) SSH-Zugang einrichten"
    echo "4) Container-Status anzeigen"
    echo "5) Zurück zum Hauptmenü"
    echo
    
    while true; do
        read -p "Wähle eine Aktion [1-5]: " action
        
        case $action in
            1)
                log_info "Starte interaktive Shell im Container..."
                echo "Tipp: Führe './ansible.sh' aus, um Ansible zu installieren"
                echo "Exit mit 'exit' oder Ctrl+D"
                docker exec -it "$container_name" /bin/bash
                ;;
            2)
                log_info "Führe Ansible-Installation im Container aus..."
                echo
                echo "Verfügbare Installationen:"
                echo "1) Basis-Installation"
                echo "2) Vollständige Installation"
                echo "3) Minimale Installation"
                
                read -p "Wähle Installation [1-3]: " install_type
                
                case $install_type in
                    1) docker exec -it "$container_name" /bin/bash -c "cd /home/developer && ./ansible.sh" ;;
                    2) docker exec -it "$container_name" /bin/bash -c "cd /home/developer && echo '2' | ./ansible.sh" ;;
                    3) docker exec -it "$container_name" /bin/bash -c "cd /home/developer && echo '3' | ./ansible.sh" ;;
                    *) log_error "Ungültige Auswahl" ;;
                esac
                ;;
            3)
                log_info "SSH-Zugang zum Container:"
                echo "ssh developer@localhost -p 2223"
                echo "Password: developer"
                
                # SSH-Schlüssel kopieren falls vorhanden
                if [ -f ~/.ssh/id_rsa.pub ]; then
                    read -p "SSH-Schlüssel zum Container kopieren? (y/N): " -n 1 -r
                    echo
                    if [[ $REPLY =~ ^[Yy]$ ]]; then
                        docker exec "$container_name" mkdir -p /home/developer/.ssh
                        docker cp ~/.ssh/id_rsa.pub "$container_name:/home/developer/.ssh/authorized_keys"
                        docker exec "$container_name" chown -R developer:developer /home/developer/.ssh
                        docker exec "$container_name" chmod 700 /home/developer/.ssh
                        docker exec "$container_name" chmod 600 /home/developer/.ssh/authorized_keys
                        log_success "SSH-Schlüssel kopiert. Login ohne Passwort möglich."
                    fi
                fi
                ;;
            4)
                log_info "Container-Status:"
                docker ps --filter "name=$container_name" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
                echo
                log_info "Container-Resourcen:"
                docker stats "$container_name" --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
                ;;
            5)
                log_info "Zurück zum Hauptmenü..."
                return 0
                ;;
            *)
                log_error "Ungültige Auswahl [1-5]"
                ;;
        esac
        
        echo
        log_info "Weitere Aktionen verfügbar..."
    done
}

# Container cleanup-Funktion
cleanup_containers() {
    log_info "Container-Cleanup..."
    
    echo "Verfügbare Container:"
    if ! list_ansible_containers; then
        log_info "Keine Container zum Löschen gefunden"
        return 0
    fi
    
    echo
    echo "Container-Engine wählen:"
    echo "1) Docker-Container löschen"
    echo "2) Podman-Container löschen"
    echo "3) Alle Container (Docker + Podman) löschen"
    echo "4) Abbrechen"
    
    read -p "Engine wählen [1-4]: " engine_choice
    
    case $engine_choice in
        1)
            cleanup_docker_containers
            ;;
        2)
            cleanup_podman_containers
            ;;
        3)
            cleanup_docker_containers
            cleanup_podman_containers
            ;;
        4)
            log_info "Abgebrochen"
            ;;
        *)
            log_error "Ungültige Auswahl"
            ;;
    esac
}

# Docker-Container-Cleanup
cleanup_docker_containers() {
    if ! command -v docker >/dev/null 2>&1; then
        log_info "Docker nicht verfügbar"
        return 0
    fi
    
    echo
    echo "Docker-Container Optionen:"
    echo "1) Alle Docker-Container löschen"
    echo "2) Nur gestoppte Docker-Container löschen"
    echo "3) Bestimmten Docker-Container löschen"
    echo "4) Alte Docker-Container (>4 Wochen) löschen"
    echo "5) Zurück"
    
    read -p "Wähle Option [1-5]: " choice
    
    case $choice in
        1)
            read -p "Wirklich ALLE Docker-Container löschen? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                docker ps -a --filter "name=-docker" --format "{{.Names}}" | xargs -r docker rm -f
                docker ps -a --filter "name=ansible-" --format "{{.Names}}" | xargs -r docker rm -f
                log_success "Alle Docker-Container gelöscht"
            fi
            ;;
        2)
            docker ps -a --filter "name=-docker" --filter "status=exited" --format "{{.Names}}" | xargs -r docker rm
            docker ps -a --filter "name=ansible-" --filter "status=exited" --format "{{.Names}}" | xargs -r docker rm
            log_success "Gestoppte Docker-Container gelöscht"
            ;;
        3)
            read -p "Docker-Container-Name eingeben: " container_name
            if [ -n "$container_name" ]; then
                docker rm -f "$container_name" && log_success "Docker-Container '$container_name' gelöscht"
            fi
            ;;
        4)
            cleanup_old_containers  # Existing function for Docker
            ;;
        5)
            return 0
            ;;
        *)
            log_error "Ungültige Auswahl"
            ;;
    esac
}

# Podman-Container-Cleanup
cleanup_podman_containers() {
    if ! command -v podman >/dev/null 2>&1; then
        log_info "Podman nicht verfügbar"
        return 0
    fi
    
    echo
    echo "Podman-Container Optionen:"
    echo "1) Alle Podman-Container löschen"
    echo "2) Nur gestoppte Podman-Container löschen"
    echo "3) Bestimmten Podman-Container löschen"
    echo "4) Alte Podman-Container (>4 Wochen) löschen"
    echo "5) Zurück"
    
    read -p "Wähle Option [1-5]: " choice
    
    case $choice in
        1)
            read -p "Wirklich ALLE Podman-Container löschen? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                podman ps -a --filter "name=ansible" --format "{{.Names}}" | xargs -r podman rm -f
                log_success "Alle Podman-Container gelöscht"
            fi
            ;;
        2)
            podman ps -a --filter "name=ansible" --filter "status=exited" --format "{{.Names}}" | xargs -r podman rm
            log_success "Gestoppte Podman-Container gelöscht"
            ;;
        3)
            read -p "Podman-Container-Name eingeben: " container_name
            if [ -n "$container_name" ]; then
                podman rm -f "$container_name" && log_success "Podman-Container '$container_name' gelöscht"
            fi
            ;;
        4)
            cleanup_old_podman_containers
            ;;
        5)
            return 0
            ;;
        *)
            log_error "Ungültige Auswahl"
            ;;
    esac
}

# Alte Podman-Container löschen
cleanup_old_podman_containers() {
    log_info "Suche nach alten Podman-Containern (älter als 4 Wochen)..."
    
    local current_year=$(date +%y)
    local current_week=$(date +%V)
    local cutoff_week=$((current_week - 4))
    
    if [ $cutoff_week -le 0 ]; then
        cutoff_week=$((52 + cutoff_week))
        current_year=$((current_year - 1))
        current_year=$(printf "%02d" $current_year)
    fi
    
    local old_containers=$(podman ps -a --filter "name=ansible" --format "{{.Names}}" | while read container; do
        if [[ $container =~ ([0-9]{2})KW([0-9]+)-docker ]]; then
            local year=${BASH_REMATCH[1]}
            local week=${BASH_REMATCH[2]}
            
            local full_year=$((2000 + 10#$year))
            local current_full_year=$((2000 + 10#$current_year))
            
            if [ $full_year -lt $current_full_year ] || ([ $full_year -eq $current_full_year ] && [ $((10#$week)) -lt $cutoff_week ]); then
                echo $container
            fi
        fi
    done)
    
    if [ -z "$old_containers" ]; then
        log_info "Keine alten Podman-Container gefunden."
        return 0
    fi
    
    echo "Gefundene alte Podman-Container:"
    echo "$old_containers"
    echo
    
    read -p "Diese Podman-Container löschen? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$old_containers" | while read container; do
            podman rm -f "$container" && log_success "Podman-Container '$container' gelöscht"
        done
    fi
}

# Installation testen
test_installation() {
    log_info "Teste Ansible-Installation..."
    
    # Version prüfen
    if ansible --version; then
        log_success "Ansible ist funktionstüchtig"
    else
        log_error "Ansible-Test fehlgeschlagen"
        return 1
    fi
    
    # Lokaler Test
    echo "---
- hosts: localhost
  connection: local
  tasks:
    - debug: msg='Ansible Test erfolgreich!'" > /tmp/ansible-test.yml
    
    if ansible-playbook /tmp/ansible-test.yml; then
        log_success "Playbook-Test erfolgreich"
    else
        log_error "Playbook-Test fehlgeschlagen"
        return 1
    fi
    
    rm /tmp/ansible-test.yml
}

# Cleanup-Funktion
cleanup() {
    log_info "Räume temporäre Dateien auf..."
    rm -f /tmp/ansible-test.yml
}

# Installation-Optionen
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

do_custom_install() {
    echo
    log_info "Custom Installation - wähle Komponenten:"
    
    components=(
        "Basis-Pakete"
        "Docker"
        "VSCode"
        "Zusätzliche Tools"
        "SSH-Schlüssel"
        "Ansible-Config"
        "Projekt-Template"
        "Docker Test-Container"
    )
    
    selected=()
    
    for i in "${!components[@]}"; do
        read -p "Installiere ${components[$i]}? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            selected+=($i)
        fi
    done
    
    update_system
    
    for i in "${selected[@]}"; do
        case $i in
            0) install_base_packages ;;
            1) install_docker ;;
            2) install_vscode ;;
            3) install_additional_tools ;;
            4) setup_ssh_keys ;;
            5) setup_ansible_config ;;
            6) create_project_template ;;
            7) setup_docker_test ;;
        esac
    done
    
    test_installation
}

# Hauptfunktion
main() {
    show_banner
    check_root
    check_manjaro
    
    # Cleanup bei Exit
    trap cleanup EXIT
    
    while true; do
        show_menu
        read -p "Wähle eine Option [1-10]: " choice
        
        case $choice in
            1)
                log_info "Starte Basis-Installation..."
                do_base_install
                break
                ;;
            2)
                log_info "Starte vollständige Installation..."
                do_full_install
                break
                ;;
            3)
                log_info "Starte minimale Installation..."
                do_minimal_install
                break
                ;;
            4)
                do_custom_install
                break
                ;;
            5)
                log_info "Richte nur Testumgebung ein..."
                setup_docker_test
                break
                ;;
            6)
                log_info "Starte Docker-Container für isolierte Installation..."
                run_in_docker_container
                ;;
            7)
                log_info "🚀 Automatische KW-Container-Erstellung + Vollinstallation (Docker)..."
                create_weekly_container_auto
                break
                ;;
            8)
                log_info "🐳 Automatische KW-Container-Erstellung + Vollinstallation (Podman - ROOTLESS)..."
                create_podman_container_auto
                break
                ;;
            9)
                manage_containers
                ;;
            10)
                log_info "Installation abgebrochen"
                
                # Cleanup-Option anbieten
                read -p "Container aufräumen vor dem Beenden? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    cleanup_containers
                fi
                
                exit 0
                ;;
            *)
                log_error "Ungültige Auswahl. Bitte 1-10 wählen."
                ;;
        esac
    done
    
    echo
    log_success "Installation abgeschlossen!"
    echo
    log_info "🚀 Nächste Schritte:"
    echo "1. Terminal neu starten (für Docker-Gruppe)"
    echo "2. Für KW-Container: ./ansible.sh → Option 7"
    echo "3. Container-Management: ./ansible.sh → Option 8"
    echo "4. cd ~/ansible-projekte/webserver-beispiel"
    echo "5. ansible-playbook playbooks/test.yml"
    echo
    log_info "🐳 Container-Features:"
    echo "• Automatische KW-Container: docker_$(get_calendar_week)"
    echo "• Persistente Volumes für Projekte"
    echo "• SSH-Zugang aktiviert"
    echo "• Vollständige Ansible-Installation"
    echo
    log_info "📚 Hilfe:"
    echo "• ansible --help"
    echo "• docker ps (Container anzeigen)"
    echo "• Dokumentation: https://docs.ansible.com/"
    echo
    log_success "Aktueller Container: $(get_current_container_name)"
}

# Script starten
main "$@"