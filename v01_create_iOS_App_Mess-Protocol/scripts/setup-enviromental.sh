#!/bin/bash

# Environment Setup for Ansible iOS/Android Generator
# Installs and configures all required dependencies
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
║   🔧 ENVIRONMENT SETUP - ANSIBLE iOS GENERATOR              ║
║   Automated Development Environment Configuration            ║
║                                                              ║
║   Features: Node.js | Python | Ansible | Ionic | Tools     ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${BLUE}🚀 Starting Environment Setup v${SCRIPT_VERSION}${NC}"
echo "================================================="
echo -e "${YELLOW}This script will install all required dependencies${NC}"
echo -e "${YELLOW}Date: $(date)${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get OS information
get_os_info() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="$(sw_vers -productName)"
        VERSION="$(sw_vers -productVersion)"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            DISTRO="$NAME"
            VERSION="$VERSION_ID"
        else
            DISTRO="Unknown Linux"
            VERSION="Unknown"
        fi
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        DISTRO="Windows"
        VERSION="$(cmd.exe /c ver | grep -oP '\d+\.\d+\.\d+')"
    else
        OS="unknown"
        DISTRO="Unknown"
        VERSION="Unknown"
    fi
}

# Function to install package based on OS
install_package() {
    local package=$1
    local description=${2:-$package}
    
    echo -e "${YELLOW}📦 Installing $description...${NC}"
    
    case $OS in
        "macos")
            if command_exists brew; then
                brew install "$package"
            else
                echo -e "${RED}❌ Homebrew not found. Installing Homebrew first...${NC}"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                brew install "$package"
            fi
            ;;
        "linux")
            if command_exists apt-get; then
                sudo apt-get update && sudo apt-get install -y "$package"
            elif command_exists yum; then
                sudo yum install -y "$package"
            elif command_exists dnf; then
                sudo dnf install -y "$package"
            elif command_exists pacman; then
                sudo pacman -S --noconfirm "$package"
            elif command_exists zypper; then
                sudo zypper install -y "$package"
            else
                echo -e "${RED}❌ No supported package manager found${NC}"
                echo -e "${YELLOW}Please install $description manually${NC}"
                return 1
            fi
            ;;
        "windows")
            if command_exists choco; then
                choco install "$package" -y
            elif command_exists winget; then
                winget install "$package"
            else
                echo -e "${RED}❌ No package manager found (Chocolatey/Winget)${NC}"
                echo -e "${YELLOW}Please install $description manually${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}❌ Unsupported OS: $OS${NC}"
            return 1
            ;;
    esac
}

# Show system information
show_system_info() {
    echo -e "${PURPLE}💻 SYSTEM INFORMATION${NC}"
    echo "========================"
    echo "Operating System: $DISTRO $VERSION"
    echo "Architecture: $(uname -m)"
    echo "User: $(whoami)"
    echo "Home Directory: $HOME"
    echo "Shell: $SHELL"
    echo "Working Directory: $(pwd)"
    echo ""
}

# Check and install Python
setup_python() {
    echo -e "${BLUE}🐍 Setting up Python environment...${NC}"
    
    if ! command_exists python3; then
        echo -e "${YELLOW}⚠️ Python 3 not found. Installing...${NC}"
        case $OS in
            "macos")
                install_package python3 "Python 3"
                ;;
            "linux")
                install_package python3 "Python 3"
                install_package python3-pip "Python 3 pip"
                install_package python3-venv "Python 3 venv"
                ;;
            "windows")
                install_package python "Python 3"
                ;;
        esac
    else
        echo -e "${GREEN}✅ Python 3 found: $(python3 --version)${NC}"
    fi
    
    # Install pip if not present
    if ! command_exists pip3; then
        echo -e "${YELLOW}⚠️ pip3 not found. Installing...${NC}"
        case $OS in
            "macos")
                curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
                python3 get-pip.py
                rm get-pip.py
                ;;
            "linux")
                install_package python3-pip "Python 3 pip"
                ;;
            "windows")
                python -m ensurepip --upgrade
                ;;
        esac
    else
        echo -e "${GREEN}✅ pip3 found: $(pip3 --version)${NC}"
    fi
    
    # Upgrade pip
    echo -e "${BLUE}📦 Upgrading pip...${NC}"
    python3 -m pip install --upgrade pip
}

# Check and install Ansible
setup_ansible() {
    echo -e "${BLUE}🤖 Setting up Ansible...${NC}"
    
    if ! command_exists ansible-playbook; then
        echo -e "${YELLOW}⚠️ Ansible not found. Installing...${NC}"
        
        # Install via pip (most reliable method)
        python3 -m pip install --user ansible
        
        # Add to PATH if needed
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            export PATH="$HOME/.local/bin:$PATH"
            case $SHELL in
                */bash)
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
                    ;;
                */zsh)
                    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
                    ;;
                */fish)
                    echo 'set -gx PATH $HOME/.local/bin $PATH' >> ~/.config/fish/config.fish
                    ;;
            esac
            echo -e "${YELLOW}⚠️ Added $HOME/.local/bin to PATH. Please restart your shell.${NC}"
        fi
        
        # Verify installation
        if ! command_exists ansible-playbook; then
            echo -e "${RED}❌ Ansible installation failed${NC}"
            echo -e "${YELLOW}Trying alternative installation method...${NC}"
            
            case $OS in
                "macos")
                    install_package ansible "Ansible"
                    ;;
                "linux")
                    install_package ansible "Ansible"
                    ;;
                "windows")
                    echo -e "${RED}❌ Ansible is not natively supported on Windows${NC}"
                    echo -e "${YELLOW}Please use WSL2 or Docker${NC}"
                    return 1
                    ;;
            esac
        fi
    else
        echo -e "${GREEN}✅ Ansible found: $(ansible --version | head -n1)${NC}"
    fi
    
    # Install additional Ansible collections
    echo -e "${BLUE}📦 Installing Ansible collections...${NC}"
    ansible-galaxy collection install community.general || true
    ansible-galaxy collection install ansible.posix || true
}

# Check and install Node.js
setup_nodejs() {
    echo -e "${BLUE}📦 Setting up Node.js environment...${NC}"
    
    if ! command_exists node; then
        echo -e "${YELLOW}⚠️ Node.js not found. Installing...${NC}"
        
        case $OS in
            "macos")
                install_package node "Node.js"
                ;;
            "linux")
                # Use NodeSource repository for latest version
                curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
                sudo apt-get install -y nodejs
                ;;
            "windows")
                install_package nodejs "Node.js"
                ;;
        esac
        
        if ! command_exists node; then
            echo -e "${RED}❌ Node.js installation failed${NC}"
            echo -e "${YELLOW}Please install Node.js manually from: https://nodejs.org${NC}"
            return 1
        fi
    else
        echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"
    fi
    
    if ! command_exists npm; then
        echo -e "${RED}❌ npm not found with Node.js installation${NC}"
        return 1
    else
        echo -e "${GREEN}✅ npm found: $(npm --version)${NC}"
    fi
    
    # Update npm to latest version
    echo -e "${BLUE}📦 Updating npm...${NC}"
    npm install -g npm@latest
}

# Install global Node.js packages
setup_nodejs_tools() {
    echo -e "${BLUE}⚡ Installing Node.js development tools...${NC}"
    
    # Essential tools
    local tools=(
        "@ionic/cli"
        "@capacitor/cli"
        "typescript"
        "eslint"
        "prettier"
    )
    
    for tool in "${tools[@]}"; do
        echo -e "${YELLOW}📦 Installing $tool globally...${NC}"
        npm install -g "$tool" || {
            echo -e "${RED}❌ Failed to install $tool${NC}"
            echo -e "${YELLOW}Will be installed with project dependencies${NC}"
        }
    done
    
    # Verify installations
    if command_exists ionic; then
        echo -e "${GREEN}✅ Ionic CLI: $(ionic --version)${NC}"
    fi
    
    if command_exists cap; then
        echo -e "${GREEN}✅ Capacitor CLI: $(cap --version)${NC}"
    fi
}

# Install development tools
setup_dev_tools() {
    echo -e "${BLUE}🛠️ Setting up development tools...${NC}"
    
    # Git
    if ! command_exists git; then
        echo -e "${YELLOW}⚠️ Git not found. Installing...${NC}"
        install_package git "Git"
    else
        echo -e "${GREEN}✅ Git found: $(git --version)${NC}"
    fi
    
    # Curl
    if ! command_exists curl; then
        echo -e "${YELLOW}⚠️ curl not found. Installing...${NC}"
        install_package curl "curl"
    else
        echo -e "${GREEN}✅ curl found: $(curl --version | head -n1)${NC}"
    fi
    
    # Wget
    if ! command_exists wget; then
        echo -e "${YELLOW}⚠️ wget not found. Installing...${NC}"
        install_package wget "wget"
    else
        echo -e "${GREEN}✅ wget found${NC}"
    fi
    
    # Unzip
    if ! command_exists unzip; then
        echo -e "${YELLOW}⚠️ unzip not found. Installing...${NC}"
        install_package unzip "unzip"
    else
        echo -e "${GREEN}✅ unzip found${NC}"
    fi
}

# Setup mobile development environment
setup_mobile_dev() {
    echo -e "${BLUE}📱 Setting up mobile development environment...${NC}"
    
    case $OS in
        "macos")
            echo -e "${YELLOW}🍎 macOS detected - iOS development possible${NC}"
            
            # Check for Xcode
            if command_exists xcodebuild; then
                echo -e "${GREEN}✅ Xcode found: $(xcodebuild -version | head -n1)${NC}"
            else
                echo -e "${YELLOW}⚠️ Xcode not found${NC}"
                echo -e "${WHITE}Please install Xcode from the App Store for iOS development${NC}"
            fi
            
            # Check for Xcode Command Line Tools
            if xcode-select -p &>/dev/null; then
                echo -e "${GREEN}✅ Xcode Command Line Tools installed${NC}"
            else
                echo -e "${YELLOW}⚠️ Installing Xcode Command Line Tools...${NC}"
                xcode-select --install
            fi
            
            # Install CocoaPods
            if ! command_exists pod; then
                echo -e "${YELLOW}📦 Installing CocoaPods...${NC}"
                sudo gem install cocoapods
            else
                echo -e "${GREEN}✅ CocoaPods found: $(pod --version)${NC}"
            fi
            ;;
        "linux")
            echo -e "${YELLOW}🐧 Linux detected - Android development possible${NC}"
            ;;
        "windows")
            echo -e "${YELLOW}🪟 Windows detected - Android development possible${NC}"
            ;;
    esac
    
    # Android SDK check
    if [[ -n "$ANDROID_HOME" ]] && [[ -d "$ANDROID_HOME" ]]; then
        echo -e "${GREEN}✅ Android SDK found at: $ANDROID_HOME${NC}"
    else
        echo -e "${YELLOW}⚠️ Android SDK not found${NC}"
        echo -e "${WHITE}Please install Android Studio and set ANDROID_HOME${NC}"
        echo -e "${WHITE}https://developer.android.com/studio${NC}"
    fi
    
    # Java check
    if command_exists java; then
        echo -e "${GREEN}✅ Java found: $(java -version 2>&1 | head -n1)${NC}"
    else
        echo -e "${YELLOW}⚠️ Java not found. Installing OpenJDK...${NC}"
        case $OS in
            "macos")
                install_package openjdk "OpenJDK"
                ;;
            "linux")
                install_package default-jdk "OpenJDK"
                ;;
            "windows")
                install_package openjdk "OpenJDK"
                ;;
        esac
    fi
}

# Create development directories
setup_directories() {
    echo -e "${BLUE}📁 Setting up development directories...${NC}"
    
    local dev_dirs=(
        "$HOME/Development"
        "$HOME/Development/mobile-apps"
        "$HOME/Development/ansible-projects"
        "$HOME/.local/bin"
    )
    
    for dir in "${dev_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            echo -e "${GREEN}✅ Created directory: $dir${NC}"
        else
            echo -e "${BLUE}📁 Directory exists: $dir${NC}"
        fi
    done
}

# Configure Git (if needed)
setup_git_config() {
    echo -e "${BLUE}🔧 Checking Git configuration...${NC}"
    
    if ! git config --global user.name &>/dev/null; then
        echo -e "${YELLOW}⚠️ Git user.name not configured${NC}"
        read -p "Enter your Git username: " git_username
        git config --global user.name "$git_username"
        echo -e "${GREEN}✅ Git username configured${NC}"
    else
        echo -e "${GREEN}✅ Git username: $(git config --global user.name)${NC}"
    fi
    
    if ! git config --global user.email &>/dev/null; then
        echo -e "${YELLOW}⚠️ Git user.email not configured${NC}"
        read -p "Enter your Git email: " git_email
        git config --global user.email "$git_email"
        echo -e "${GREEN}✅ Git email configured${NC}"
    else
        echo -e "${GREEN}✅ Git email: $(git config --global user.email)${NC}"
    fi
    
    # Set some useful Git defaults
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global core.autocrlf input
}

# Verify installation
verify_installation() {
    echo -e "${BLUE}🔍 Verifying installation...${NC}"
    echo "================================="
    
    local required_tools=(
        "python3:Python 3"
        "pip3:Python pip"
        "ansible-playbook:Ansible"
        "node:Node.js"
        "npm:npm"
        "git:Git"
        "curl:curl"
    )
    
    local optional_tools=(
        "ionic:Ionic CLI"
        "cap:Capacitor CLI"
        "code:VS Code"
        "xcodebuild:Xcode"
        "java:Java"
    )
    
    echo -e "${YELLOW}Required Tools:${NC}"
    for tool_info in "${required_tools[@]}"; do
        IFS=':' read -r cmd desc <<< "$tool_info"
        if command_exists "$cmd"; then
            echo -e "${GREEN}✅ $desc${NC}"
        else
            echo -e "${RED}❌ $desc${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Optional Tools:${NC}"
    for tool_info in "${optional_tools[@]}"; do
        IFS=':' read -r cmd desc <<< "$tool_info"
        if command_exists "$cmd"; then
            echo -e "${GREEN}✅ $desc${NC}"
        else
            echo -e "${YELLOW}⚠️ $desc (optional)${NC}"
        fi
    done
}

# Show final instructions
show_final_instructions() {
    echo ""
    echo -e "${CYAN}🎉 ENVIRONMENT SETUP COMPLETE! 🎉${NC}"
    echo -e "${CYAN}====================================${NC}"
    echo ""
    echo -e "${PURPLE}💡 NEXT STEPS:${NC}"
    echo -e "${WHITE}1. Restart your terminal/shell${NC}"
    echo -e "${WHITE}2. Run: ./scripts/run-playbook.sh${NC}"
    echo -e "${WHITE}3. Start developing your mobile app!${NC}"
    echo ""
    echo -e "${PURPLE}📚 USEFUL RESOURCES:${NC}"
    echo -e "${WHITE}- Ionic Documentation: https://ionicframework.com/docs${NC}"
    echo -e "${WHITE}- Capacitor Documentation: https://capacitorjs.com/docs${NC}"
    echo -e "${WHITE}- Ansible Documentation: https://docs.ansible.com${NC}"
    echo ""
    echo -e "${PURPLE}🆘 SUPPORT:${NC}"
    echo -e "${WHITE}- GitHub Issues: Create an issue if you encounter problems${NC}"
    echo -e "${WHITE}- Community: Join the Ionic/Capacitor communities${NC}"
    echo ""
    echo -e "${GREEN}📱 Happy Mobile Development! 🚀${NC}"
}

# ========================================
# MAIN EXECUTION
# ========================================

# Get system information
get_os_info

# Show system info
show_system_info

# Setup all components
echo -e "${YELLOW}🚀 Starting complete environment setup...${NC}"
echo ""

setup_python
setup_ansible
setup_nodejs
setup_nodejs_tools
setup_dev_tools
setup_mobile_dev
setup_directories
setup_git_config

# Verify everything is working
verify_installation

# Show final instructions
show_final_instructions

echo -e "${CYAN}Environment setup completed successfully! 🎊${NC}"