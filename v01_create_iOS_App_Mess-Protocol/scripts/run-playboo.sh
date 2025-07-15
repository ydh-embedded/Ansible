#!/bin/bash

# Ansible iOS/Android Project Generator Runner
# Ultimate Script to execute the Ansible playbook with all checks and setup
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAYBOOK_DIR="$(dirname "$SCRIPT_DIR")"
SCRIPT_VERSION="2.0.0"

# Colors for beautiful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ASCII Art Banner
echo -e "${CYAN}"
cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   🚀 ANSIBLE iOS/ANDROID PROJECT GENERATOR v2.0             ║
║   Ultimate Mobile App Development Automation                 ║
║                                                              ║
║   Features: Ansible | Ionic | Capacitor | iOS | Android     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}🎯 Starting Ansible iOS/Android Project Generator${NC}"
echo "==========================================================="
echo -e "${YELLOW}Version: ${SCRIPT_VERSION}${NC}"
echo -e "${YELLOW}Date: $(date)${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install package based on OS
install_package() {
    local package=$1
    echo -e "${YELLOW}📦 Installing $package...${NC}"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install "$package"
        else
            echo -e "${RED}❌ Homebrew not found. Please install $package manually${NC}"
            return 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y "$package"
        elif command_exists yum; then
            sudo yum install -y "$package"
        elif command_exists dnf; then
            sudo dnf install -y "$package"
        elif command_exists pacman; then
            sudo pacman -S --noconfirm "$package"
        else
            echo -e "${RED}❌ Package manager not found. Please install $package manually${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Unsupported OS. Please install $package manually${NC}"
        return 1
    fi
}

# Check and install Ansible
check_ansible() {
    echo -e "${BLUE}🔍 Checking Ansible installation...${NC}"
    
    if ! command_exists ansible-playbook; then
        echo -e "${YELLOW}⚠️ Ansible not found. Installing...${NC}"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            install_package ansible
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Try pip installation first (more universal)
            if command_exists pip3; then
                pip3 install --user ansible
                # Add to PATH if not already there
                if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                    export PATH="$HOME/.local/bin:$PATH"
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
                fi
            else
                install_package ansible
            fi
        fi
        
        # Verify installation
        if ! command_exists ansible-playbook; then
            echo -e "${RED}❌ Ansible installation failed${NC}"
            echo -e "${RED}Please install Ansible manually:${NC}"
            echo -e "${WHITE}https://docs.ansible.com/ansible/latest/installation_guide/index.html${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✅ Ansible found: $(ansible --version | head -n1)${NC}"
}

# Check Python and required dependencies
check_python() {
    echo -e "${BLUE}🐍 Checking Python installation...${NC}"
    
    if ! command_exists python3; then
        echo -e "${YELLOW}⚠️ Python 3 not found. Installing...${NC}"
        install_package python3
    fi
    
    if ! command_exists pip3; then
        echo -e "${YELLOW}⚠️ pip3 not found. Installing...${NC}"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            install_package python3-pip
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            install_package python3-pip
        fi
    fi
    
    echo -e "${GREEN}✅ Python found: $(python3 --version)${NC}"
}

# Check Node.js and npm
check_nodejs() {
    echo -e "${BLUE}📦 Checking Node.js installation...${NC}"
    
    if ! command_exists node; then
        echo -e "${YELLOW}⚠️ Node.js not found. Installing...${NC}"
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            install_package node
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Install Node.js via NodeSource repository
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
        
        if ! command_exists node; then
            echo -e "${RED}❌ Node.js installation failed${NC}"
            echo -e "${YELLOW}Please install Node.js manually from: https://nodejs.org${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"
    echo -e "${GREEN}✅ npm found: $(npm --version)${NC}"
}

# Check Ionic CLI
check_ionic() {
    echo -e "${BLUE}⚡ Checking Ionic CLI...${NC}"
    
    if ! command_exists ionic; then
        echo -e "${YELLOW}⚠️ Ionic CLI not found. Installing...${NC}"
        npm install -g @ionic/cli
        
        if ! command_exists ionic; then
            echo -e "${RED}❌ Ionic CLI installation failed${NC}"
            echo -e "${YELLOW}Please install manually: npm install -g @ionic/cli${NC}"
            # Don't exit - not critical for Ansible playbook
        else
            echo -e "${GREEN}✅ Ionic CLI installed: $(ionic --version)${NC}"
        fi
    else
        echo -e "${GREEN}✅ Ionic CLI found: $(ionic --version)${NC}"
    fi
}

# Check Capacitor CLI
check_capacitor() {
    echo -e "${BLUE}📱 Checking Capacitor CLI...${NC}"
    
    if ! command_exists cap; then
        echo -e "${YELLOW}⚠️ Capacitor CLI not found. Installing...${NC}"
        npm install -g @capacitor/cli
        
        if ! command_exists cap; then
            echo -e "${YELLOW}⚠️ Capacitor CLI installation failed${NC}"
            echo -e "${YELLOW}Will be installed with project dependencies${NC}"
        else
            echo -e "${GREEN}✅ Capacitor CLI installed: $(cap --version)${NC}"
        fi
    else
        echo -e "${GREEN}✅ Capacitor CLI found: $(cap --version)${NC}"
    fi
}

# Validate Ansible setup
validate_ansible_setup() {
    echo -e "${BLUE}🔧 Validating Ansible setup...${NC}"
    
    cd "$PLAYBOOK_DIR"
    
    # Check if playbook exists
    if [[ ! -f "playbook.yml" ]]; then
        echo -e "${RED}❌ playbook.yml not found in $PLAYBOOK_DIR${NC}"
        exit 1
    fi
    
    # Check if inventory exists
    if [[ ! -f "inventory.yml" ]]; then
        echo -e "${RED}❌ inventory.yml not found in $PLAYBOOK_DIR${NC}"
        exit 1
    fi
    
    # Validate playbook syntax
    if ! ansible-playbook playbook.yml --syntax-check; then
        echo -e "${RED}❌ Playbook syntax validation failed${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Ansible setup validated${NC}"
}

# Show system information
show_system_info() {
    echo -e "${PURPLE}💻 SYSTEM INFORMATION${NC}"
    echo "========================"
    echo "OS: $(uname -s) $(uname -r)"
    echo "Architecture: $(uname -m)"
    echo "User: $(whoami)"
    echo "Working Directory: $(pwd)"
    echo "Date: $(date)"
    echo ""
}

# Show available tags
show_available_tags() {
    echo -e "${PURPLE}🏷️ AVAILABLE ANSIBLE TAGS${NC}"
    echo "============================"
    echo "setup, core    - Basic project setup"
    echo "web, assets    - Web assets creation"
    echo "dev, tools     - Development tools"
    echo "mobile         - Mobile platform setup"
    echo "all            - All tasks (default)"
    echo ""
}

# Interactive mode
run_interactive() {
    echo -e "${YELLOW}🎮 INTERACTIVE MODE${NC}"
    echo "==================="
    echo ""
    
    # Ask for specific tags
    echo -e "${BLUE}Would you like to run specific tasks only? (y/n)${NC}"
    read -p "> " use_tags
    
    ANSIBLE_ARGS=""
    if [[ "$use_tags" =~ ^[Yy] ]]; then
        show_available_tags
        echo -e "${BLUE}Enter tags (comma-separated, e.g., setup,web):${NC}"
        read -p "> " tags
        if [[ -n "$tags" ]]; then
            ANSIBLE_ARGS="--tags $tags"
        fi
    fi
    
    # Ask for verbose output
    echo -e "${BLUE}Enable verbose output? (y/n)${NC}"
    read -p "> " verbose
    if [[ "$verbose" =~ ^[Yy] ]]; then
        ANSIBLE_ARGS="$ANSIBLE_ARGS -vv"
    fi
    
    # Ask for dry run
    echo -e "${BLUE}Run in check mode (dry run)? (y/n)${NC}"
    read -p "> " dryrun
    if [[ "$dryrun" =~ ^[Yy] ]]; then
        ANSIBLE_ARGS="$ANSIBLE_ARGS --check"
    fi
    
    return 0
}

# Main execution function
run_ansible_playbook() {
    echo -e "${BLUE}🚀 Running Ansible playbook...${NC}"
    echo "================================="
    
    cd "$PLAYBOOK_DIR"
    
    # Default arguments
    local ansible_args="-i inventory.yml playbook.yml"
    
    # Add interactive arguments if set
    if [[ -n "$ANSIBLE_ARGS" ]]; then
        ansible_args="$ansible_args $ANSIBLE_ARGS"
    fi
    
    echo -e "${YELLOW}Command: ansible-playbook $ansible_args${NC}"
    echo ""
    
    # Run the playbook
    if ansible-playbook $ansible_args; then
        echo ""
        echo -e "${GREEN}🎉 ANSIBLE PLAYBOOK COMPLETED SUCCESSFULLY! 🎉${NC}"
        echo -e "${GREEN}============================================${NC}"
        show_next_steps
    else
        echo ""
        echo -e "${RED}❌ ANSIBLE PLAYBOOK FAILED${NC}"
        echo -e "${RED}========================${NC}"
        echo -e "${YELLOW}Check the error messages above for details${NC}"
        exit 1
    fi
}

# Show next steps
show_next_steps() {
    echo -e "${CYAN}💡 NEXT STEPS${NC}"
    echo "=============="
    echo -e "${WHITE}1. Navigate to your project directory${NC}"
    echo -e "${WHITE}2. Run: ionic serve${NC}"
    echo -e "${WHITE}3. Add mobile platforms: ionic cap add ios && ionic cap add android${NC}"
    echo -e "${WHITE}4. Sync code: ionic cap sync${NC}"
    echo -e "${WHITE}5. Test on devices: ionic cap run ios / android${NC}"
    echo ""
    echo -e "${CYAN}📚 USEFUL COMMANDS${NC}"
    echo "=================="
    echo -e "${WHITE}ionic serve              # Start development server${NC}"
    echo -e "${WHITE}ionic build              # Build for production${NC}"
    echo -e "${WHITE}ionic cap sync           # Sync web code to native${NC}"
    echo -e "${WHITE}ionic cap run ios        # Run on iOS simulator${NC}"
    echo -e "${WHITE}ionic cap run android    # Run on Android emulator${NC}"
    echo ""
    echo -e "${GREEN}📱 HAPPY MOBILE DEVELOPMENT! 🚀${NC}"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                ANSIBLE_ARGS="$ANSIBLE_ARGS -vv"
                shift
                ;;
            --check|--dry-run)
                ANSIBLE_ARGS="$ANSIBLE_ARGS --check"
                shift
                ;;
            --tags)
                ANSIBLE_ARGS="$ANSIBLE_ARGS --tags $2"
                shift 2
                ;;
            -i|--interactive)
                INTERACTIVE_MODE=true
                shift
                ;;
            --skip-checks)
                SKIP_CHECKS=true
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help
show_help() {
    echo -e "${CYAN}Ansible iOS/Android Project Generator${NC}"
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  -v, --verbose           Enable verbose output"
    echo "  --check, --dry-run      Run in check mode (don't make changes)"
    echo "  --tags TAGS             Run only specific tags"
    echo "  -i, --interactive       Run in interactive mode"
    echo "  --skip-checks          Skip dependency checks"
    echo ""
    echo "Examples:"
    echo "  $0                      # Run with default settings"
    echo "  $0 -i                   # Run in interactive mode"
    echo "  $0 --tags setup,web     # Run only setup and web tasks"
    echo "  $0 --check              # Dry run to see what would change"
    echo "  $0 -v                   # Run with verbose output"
}

# ========================================
# MAIN EXECUTION
# ========================================

# Initialize variables
ANSIBLE_ARGS=""
INTERACTIVE_MODE=false
SKIP_CHECKS=false

# Parse command line arguments
parse_arguments "$@"

# Show system information
show_system_info

# Run dependency checks (unless skipped)
if [[ "$SKIP_CHECKS" != "true" ]]; then
    echo -e "${YELLOW}🔍 DEPENDENCY CHECKS${NC}"
    echo "===================="
    
    check_python
    check_ansible
    check_nodejs
    check_ionic
    check_capacitor
    
    echo ""
    echo -e "${GREEN}✅ All dependency checks completed${NC}"
    echo ""
fi

# Validate Ansible setup
validate_ansible_setup

# Run interactive mode if requested
if [[ "$INTERACTIVE_MODE" == "true" ]]; then
    run_interactive
fi

# Run the Ansible playbook
run_ansible_playbook

echo -e "${CYAN}🎊 Thank you for using the Ansible iOS/Android Project Generator! 🎊${NC}"