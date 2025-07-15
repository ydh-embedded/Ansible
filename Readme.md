# 📋 Vollständige Installation - Ansible iOS/Android Generator

Dieser Guide führt Sie durch die komplette Installation und Einrichtung des Ansible iOS/Android Projekt-Generators.

## 📁 Vollständige Dateistruktur

```
ansible-ios-generator/
├── 📋 playbook.yml                          # Haupt-Ansible-Playbook
├── 📦 inventory.yml                         # Inventory-Konfiguration
├── 📖 README.md                             # Haupt-Dokumentation
├── 📋 INSTALL.md                            # Diese Installationsanleitung
├── 🌐 group_vars/
│   └── all.yml                             # Globale Variablen
├── 🎭 roles/
│   ├── project-setup/                      # Basis-Projekt-Setup
│   │   ├── tasks/
│   │   │   └── main.yml                    # Setup-Tasks
│   │   ├── templates/
│   │   │   ├── package.json.j2             # NPM Package-Konfiguration
│   │   │   ├── capacitor.config.ts.j2      # Capacitor-Konfiguration
│   │   │   ├── index.html.j2               # Haupt-HTML-Template
│   │   │   ├── style.css.j2                # CSS-Stylesheet
│   │   │   ├── app.js.j2                   # Haupt-JavaScript
│   │   │   ├── ionic.config.json.j2        # Ionic-Konfiguration
│   │   │   ├── gitignore.j2                # Git-Ignore-Datei
│   │   │   ├── README.md.j2                # Projekt-README
│   │   │   └── tsconfig.json.j2            # TypeScript-Konfiguration
│   │   └── handlers/
│   │       └── main.yml                    # Event-Handler
│   ├── web-assets/                         # Web-Assets und Module
│   │   ├── tasks/
│   │   │   └── main.yml                    # Web-Asset-Tasks
│   │   └── templates/
│   │       ├── protocol.html.j2            # Protokoll-Seite
│   │       ├── chart.js.j2                 # Chart-Modul
│   │       ├── weather.js.j2               # Wetter-Modul
│   │       ├── measurement.js.j2           # Messungs-Modul
│   │       ├── manifest.json.j2            # PWA-Manifest
│   │       └── sw.js.j2                    # Service Worker
│   ├── development-tools/                  # Entwicklungstools
│   │   ├── tasks/
│   │   │   └── main.yml                    # Dev-Tools-Tasks
│   │   └── templates/
│   │       ├── vscode-settings.json.j2     # VS Code-Einstellungen
│   │       ├── vscode-extensions.json.j2   # VS Code-Erweiterungen
│   │       ├── eslintrc.json.j2            # ESLint-Konfiguration
│   │       ├── prettierrc.json.j2          # Prettier-Konfiguration
│   │       ├── github-actions-ci.yml.j2    # CI/CD-Pipeline
│   │       ├── jest.config.js.j2           # Test-Konfiguration
│   │       ├── webpack.config.js.j2        # Build-Konfiguration
│   │       ├── analytics.sh.j2             # Analytics-Script
│   │       └── backup.sh.j2                # Backup-Script
│   └── mobile-platforms/                   # Mobile-Platform-Setup
│       ├── tasks/
│       │   └── main.yml                    # Mobile-Tasks
│       └── templates/
│           ├── ios-info.plist.j2           # iOS-Konfiguration
│           ├── android-manifest.xml.j2     # Android-Manifest
│           ├── ios-appdelegate.swift.j2    # iOS-Swift-Code
│           ├── android-mainactivity.java.j2 # Android-Java-Code
│           └── mobile-deployment.md.j2     # Mobile-Deployment-Guide
└── 🔧 scripts/
    ├── run-playbook.sh                     # Haupt-Runner-Script
    └── setup-environment.sh               # Environment-Setup
```

## 🚀 Schritt-für-Schritt Installation

### 1. **Systemanforderungen prüfen**

#### Unterstützte Betriebssysteme:
- ✅ **macOS** 11+ (Big Sur oder neuer)
- ✅ **Linux** (Ubuntu 20.04+, CentOS 8+, Fedora 34+)
- ✅ **Windows** 10+ (mit WSL2 empfohlen)

#### Mindestanforderungen:
- **RAM**: 4 GB (8 GB empfohlen)
- **Speicher**: 5 GB freier Festplattenspeicher
- **Internet**: Stabile Internetverbindung

### 2. **Repository herunterladen**

```bash
# Option A: Git Clone (empfohlen)
git clone https://github.com/yourusername/ansible-ios-generator.git
cd ansible-ios-generator

# Option B: ZIP Download
wget https://github.com/yourusername/ansible-ios-generator/archive/main.zip
unzip main.zip
cd ansible-ios-generator-main

# Skripte ausführbar machen
chmod +x scripts/*.sh
```

### 3. **Automatische Environment-Einrichtung**

```bash
# Vollautomatisches Setup (empfohlen)
./scripts/setup-environment.sh

# Das Script installiert automatisch:
# - Python 3.8+ und pip
# - Ansible 2.9+
# - Node.js 18+ und npm
# - Ionic CLI
# - Capacitor CLI
# - Entwicklungstools (Git, curl, etc.)
```

### 4. **Manuelle Installation (falls erforderlich)**

#### **macOS:**
```bash
# Homebrew installieren (falls nicht vorhanden)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Dependencies installieren
brew install python3 ansible node git
npm install -g @ionic/cli @capacitor/cli

# Xcode installieren (für iOS-Entwicklung)
# Aus dem App Store oder Developer Portal
xcode-select --install
```

#### **Ubuntu/Debian:**
```bash
# System aktualisieren
sudo apt update && sudo apt upgrade -y

# Python und Ansible
sudo apt install -y python3 python3-pip python3-venv
pip3 install --user ansible

# Node.js (via NodeSource)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Ionic und Capacitor
npm install -g @ionic/cli @capacitor/cli

# Entwicklungstools
sudo apt install -y git curl wget unzip
```

#### **CentOS/RHEL/Fedora:**
```bash
# Python und Ansible
sudo dnf install -y python3 python3-pip
pip3 install --user ansible

# Node.js
sudo dnf install -y nodejs npm

# Ionic und Capacitor
npm install -g @ionic/cli @capacitor/cli

# Entwicklungstools
sudo dnf install -y git curl wget unzip
```

#### **Windows (WSL2):**
```bash
# WSL2 mit Ubuntu installieren
wsl --install -d Ubuntu

# In WSL2 Ubuntu:
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3 python3-pip ansible nodejs npm git
npm install -g @ionic/cli @capacitor/cli
```

### 5. **Installation verifizieren**

```bash
# Alle Tools prüfen
python3 --version    # Python 3.8+
pip3 --version       # pip 20+
ansible --version    # Ansible 2.9+
node --version       # Node.js 18+
npm --version        # npm 8+
ionic --version      # Ionic CLI 7+
cap --version        # Capacitor CLI 5+
git --version        # Git 2.0+
```

### 6. **Erstes Projekt erstellen**

```bash
# Interaktiver Modus (empfohlen für Anfänger)
./scripts/run-playbook.sh --interactive

# Express-Modus mit Standardeinstellungen
./scripts/run-playbook.sh

# Direkter Ansible-Aufruf
ansible-playbook -i inventory.yml playbook.yml
```

## 🎯 Konfigurationsoptionen

### **Während der Ausführung:**
- **Projekt-Name**: Standard ist "iOS-v00"
- **Feature-Level**: 1-6 (Basic bis Enterprise)
- **GitHub-Username**: Für Repository-Links
- **Auto-Deploy**: GitHub Pages Deployment
- **Cloud-Backup**: Automatische Backups

### **Feature-Level Übersicht:**

| Level | Features | Geeignet für |
|-------|----------|-------------|
| **1** | 🏃 Basic Setup | Anfänger, Prototyping |
| **2** | 🔍 + Code Quality | Professionelle Entwicklung |
| **3** | 🏗️ + Build System | Produktions-Apps |
| **4** | 🤖 + CI/CD Pipeline | Team-Entwicklung |
| **5** | 📊 + Analytics & Backup | Enterprise-Apps |
| **6** | 🚀 FULL ENTERPRISE | Vollständige Enterprise-Lösung |

## 🎮 Verwendung nach Installation

### **Grundlegende Befehle:**

```bash
# Neues Projekt erstellen
./scripts/run-playbook.sh

# Spezifische Tags ausführen
ansible-playbook playbook.yml --tags "setup,web"

# Dry-Run (zeigt Änderungen ohne Ausführung)
ansible-playbook playbook.yml --check

# Verbose-Modus für Debugging
ansible-playbook playbook.yml -vv

# Mit benutzerdefinierten Variablen
ansible-playbook playbook.yml -e "project_name=MeinApp feature_level=4"
```

### **Projekt-Entwicklung:**

```bash
# Nach Projekt-Erstellung
cd MeinProjekt

# Dependencies installieren
npm install

# Development-Server starten
ionic serve

# Mobile-Plattformen hinzufügen
ionic cap add ios
ionic cap add android

# Code zu nativen Apps synchronisieren
ionic cap sync

# Apps auf Geräten ausführen
ionic cap run ios --device
ionic cap run android --device
```

## 🔧 Erweiterte Konfiguration

### **Anpassung der Variablen:**

Bearbeiten Sie `group_vars/all.yml`:

```yaml
# Projekt-Einstellungen
project_name: "MeineProjekt"
author_name: "Ihr Name"
author_email: "ihre.email@example.com"

# Farb-Schema
primary_color: "#007AFF"
secondary_color: "#34C759"
accent_color: "#FF9500"

# Feature-Flags
enable_quality: true
enable_analytics: true
enable_backup: true
```

### **Template-Anpassungen:**

Eigene Templates in `roles/*/templates/` erstellen oder vorhandene modifizieren.

### **Zusätzliche Roles:**

Neue Roles für spezielle Anforderungen:

```bash
mkdir -p roles/custom-feature/{tasks,templates,handlers}
# Role-Logik implementieren
# In playbook.yml einbinden
```

## 🐛 Troubleshooting

### **Häufige Probleme und Lösungen:**

#### **Ansible nicht gefunden:**
```bash
# PATH prüfen und erweitern
echo $PATH
export PATH="$HOME/.local/bin:$PATH"
source ~/.bashrc  # oder ~/.zshrc
```

#### **Permission-Fehler:**
```bash
# Berechtigungen setzen
sudo chown -R $USER:$USER ~/.local
chmod +x scripts/*.sh
```

#### **Node.js/npm Probleme:**
```bash
# Node Version Manager verwenden
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install --lts
nvm use --lts
```

#### **Ionic/Capacitor Fehler:**
```bash
# Cache leeren und neu installieren
npm cache clean --force
npm uninstall -g @ionic/cli @capacitor/cli
npm install -g @ionic/cli@latest @capacitor/cli@latest
```

#### **Mobile-Platform Probleme:**

**iOS (macOS only):**
```bash
# Xcode Command Line Tools
xcode-select --install
sudo xcode-select --reset

# CocoaPods neu installieren
sudo gem uninstall cocoapods
sudo gem install cocoapods
```

**Android:**
```bash
# Android SDK Path setzen
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

### **Debug-Befehle:**

```bash
# Ansible-Syntax prüfen
ansible-playbook playbook.yml --syntax-check

# Inventory validieren
ansible-inventory -i inventory.yml --list

# Tasks auflisten
ansible-playbook playbook.yml --list-tasks

# Variables anzeigen
ansible all -i inventory.yml -m debug -a "var=hostvars[inventory_hostname]"

# Einzelne Tasks ausführen
ansible-playbook playbook.yml --start-at-task "Task Name"
```

## 📚 Weiterführende Ressourcen

### **Offizielle Dokumentation:**
- 📖 [Ansible Docs](https://docs.ansible.com/)
- ⚡ [Ionic Framework](https://ionicframework.com/docs)
- 📱 [Capacitor](https://capacitorjs.com/docs)
- 🎨 [Ionic UI Components](https://ionicframework.com/docs/components)

### **Tutorials und Guides:**
- 🎥 [Ionic YouTube Channel](https://www.youtube.com/c/Ionicframework)
- 📝 [Capacitor Blog](https://capacitorjs.com/blog)
- 🏫 [Ansible Learning](https://www.ansible.com/resources/get-started)

### **Community:**
- 💬 [Ionic Forum](https://forum.ionicframework.com/)
- 📱 [Capacitor Discussions](https://github.com/ionic-team/capacitor/discussions)
- 🤖 [Ansible Community](https://www.ansible.com/community)

## 🤝 Support und Beitrag

### **Support erhalten:**
1. 📋 [GitHub Issues](https://github.com/yourusername/ansible-ios-generator/issues) erstellen
2. 📝 Detaillierte Problembeschreibung mit:
   - Betriebssystem und Version
   - Ansible/Node.js/Ionic Versionen
   - Fehlermeldungen
   - Schritte zur Reproduktion

### **Zum Projekt beitragen:**
1. 🍴 Repository forken
2. 🌟 Feature-Branch erstellen
3. ✨ Änderungen implementieren
4. 🧪 Tests durchführen
5. 📝 Pull Request erstellen

## 📄 Lizenz

MIT License - siehe [LICENSE](LICENSE) für vollständige Details.

---

## 🎉 Erfolgreich installiert!

Wenn Sie alle Schritte befolgt haben, sollten Sie jetzt über ein voll funktionsfähiges Ansible iOS/Android Generator System verfügen.

**Nächste Schritte:**
1. ✅ Erstellen Sie Ihr erstes Projekt mit `./scripts/run-playbook.sh`
2. 🎨 Passen Sie Templates und Konfigurationen an Ihre Bedürfnisse an
3. 📱 Entwickeln Sie fantastische mobile Apps!

**Happy Coding! 🚀📱**