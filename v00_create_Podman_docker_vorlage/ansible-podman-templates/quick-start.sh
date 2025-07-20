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
