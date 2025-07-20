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
