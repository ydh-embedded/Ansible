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
