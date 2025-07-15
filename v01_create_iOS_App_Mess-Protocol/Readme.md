# 📱 Ansible iOS/Android Project Generator v2.0

Ein vollständiges **Ansible Playbook** zur automatisierten Erstellung von iOS/Android-Projekten mit **Ionic** und **Capacitor**. 

Dieses Tool automatisiert die komplette Projekt-Erstellung und Setup-Prozesse für moderne Mobile App Development.

## 🚀 Features

### 🎯 **Core Features**
- 📱 **Cross-Platform**: iOS, Android und Web Support
- 🤖 **Vollautomatisiert**: Komplette Projektstruktur mit einem Befehl
- 🎨 **Modern UI**: Ionic Components mit Custom Styling
- 📊 **Monitoring Dashboard**: Real-time Data Visualization
- 🔧 **Development Tools**: ESLint, Prettier, VS Code Integration

### 🏗️ **Ansible Advantages**
- ✅ **Idempotent**: Mehrfache Ausführung ohne Probleme
- 🔄 **Rollback**: Fehlerbehandlung und Rückgängigmachen
- 📝 **Logging**: Detaillierte Ausführungsprotokolle
- 🏷️ **Tags**: Selektive Task-Ausführung
- 🌐 **Remote**: Ausführung auf Remote-Hosts möglich

### 📈 **Feature Levels**
1. 🏃 **Basic Setup** - Web App + Capacitor
2. 🔍 **+ Code Quality** - ESLint, Prettier
3. 🏗️ **+ Build System** - Webpack, Minification
4. 🤖 **+ CI/CD Pipeline** - GitHub Actions
5. 📊 **+ Analytics & Backup** - Monitoring & Data Backup
6. 🚀 **FULL ENTERPRISE** - All Features

## 📁 Projektstruktur

```
ansible-ios-generator/
├── 📋 playbook.yml                    # Haupt-Playbook
├── 📦 inventory.yml                   # Inventory-Datei
├── 🌐 group_vars/
│   └── all.yml                       # Globale Variablen
├── 🎭 roles/
│   ├── project-setup/                # Basis-Setup
│   │   ├── tasks/main.yml
│   │   ├── templates/
│   │   │   ├── package.json.j2
│   │   │   ├── capacitor.config.ts.j2
│   │   │   ├── index.html.j2
│   │   │   └── style.css.j2
│   │   └── handlers/main.yml
│   ├── web-assets/                   # Web-Komponenten
│   │   ├── tasks/main.yml
│   │   └── templates/
│   │       ├── app.js.j2
│   │       └── protocol.html.j2
│   ├── development-tools/            # Dev-Tools
│   │   ├── tasks/main.yml
│   │   └── templates/
│   │       ├── vscode-settings.json.j2
│   │       └── eslintrc.json.j2
│   └── mobile-platforms/             # Mobile Setup
│       ├── tasks/main.yml
│       └── templates/
└── 🔧 scripts/
    ├── run-playbook.sh              # Helper-Script
    └── setup-environment.sh         # Environment-Setup
```

## ⚡ Quick Start

### 1. **Repository Setup**
```bash
# Repository klonen
git clone <ansible-ios-generator-repo>
cd ansible-ios-generator

# Scripts ausführbar machen
chmod +x scripts/*.sh
```

### 2. **Dependencies installieren**
```bash
# Automatisches Setup (empfohlen)
./scripts/run-playbook.sh

# Oder manuell
./scripts/setup-environment.sh
```

### 3. **Projekt generieren**
```bash
# Interaktiver Modus (empfohlen)
./scripts/run-playbook.sh --interactive

# Oder direkter Start
ansible-playbook -i inventory.yml playbook.yml
```

## 🎮 Usage Modes

### 🎯 **Interaktiver Modus**
```bash
./scripts/run-playbook.sh --interactive
```
- Geführte Projekt-Konfiguration
- Feature-Level Auswahl
- Tag-basierte Ausführung

### ⚡ **Express Modus**
```bash
# Minimal Setup
ansible-playbook playbook.yml --tags "setup,web"

# Full Enterprise
ansible-playbook playbook.yml --extra-vars "feature_level=6"
```

### 🔍 **Debug Modus**
```bash
# Dry Run (zeigt was passieren würde)
ansible-playbook playbook.yml --check

# Verbose Output
ansible-playbook playbook.yml -vv

# Specific Tags only
ansible-playbook playbook.yml --tags "setup,mobile"
```

## 🏷️ Ansible Tags

| Tag | Beschreibung | Verwendung |
|-----|-------------|------------|
| `setup` | Basis-Projektstruktur | `--tags setup` |
| `core` | Kern-Komponenten | `--tags core` |
| `web` | Web Assets | `--tags web` |
| `assets` | Asset-Generierung | `--tags assets` |
| `dev` | Development Tools | `--tags dev` |
| `tools` | Tool-Konfiguration | `--tags tools` |
| `mobile` | Mobile Platforms | `--tags mobile` |
| `platforms` | Platform Setup | `--tags platforms` |
| `all` | Alle Tasks (Standard) | Kein Tag nötig |

### 🎯 **Tag Kombinationen**
```bash
# Nur Setup und Web
ansible-playbook playbook.yml --tags "setup,web"

# Nur Development Tools
ansible-playbook playbook.yml --tags "dev,tools"

# Mobile Setup ohne Web
ansible-playbook playbook.yml --tags "setup,mobile"
```

## ⚙️ Konfiguration

### 📝 **Projekt-Variablen** (group_vars/all.yml)
```yaml
# Basis-Konfiguration
project_name: "iOS-v00"
github_username: "ydh-embedded"
author_name: "Your Name"
author_email: "your.email@example.com"

# Versionen
ionic_version: "7.5.0"
capacitor_version: "5.5.0"
node_version: "18"

# Features
enable_quality: true
enable_analytics: false
enable_backup: true
```

### 🎨 **Styling-Anpassung**
```yaml
# Farben
primary_color: "#3498db"
secondary_color: "#2ecc71"
accent_color: "#f39c12"
ios_blue: "#007AFF"
```

### 📱 **App-Konfiguration**
```yaml
app_id: "com.ydh.yourapp"
app_name: "Your App"
bundle_id: "com.ydh.yourapp"
version_name: "1.0.0"
```

## 🔧 Advanced Usage

### 🌐 **Remote Execution**
```bash
# Auf Remote-Host ausführen
ansible-playbook -i production.yml playbook.yml

# Mit SSH-Key
ansible-playbook playbook.yml --private-key ~/.ssh/id_rsa
```

### 🔐 **Ansible Vault** (für Secrets)
```bash
# Verschlüsselte Variablen erstellen
ansible-vault create secrets.yml

# Playbook mit Vault ausführen
ansible-playbook playbook.yml --ask-vault-pass
```

### 📊 **Multiple Projekte**
```bash
# Verschiedene Inventories
ansible-playbook -i dev.yml playbook.yml     # Development
ansible-playbook -i prod.yml playbook.yml    # Production
ansible-playbook -i staging.yml playbook.yml # Staging
```

## 🛠️ Development Workflow

### 1. **Projekt erstellen**
```bash
./scripts/run-playbook.sh --interactive
cd MeinNeuesProjekt
```

### 2. **Development starten**
```bash
npm install
ionic serve
```

### 3. **Mobile Platforms hinzufügen**
```bash
ionic cap add ios
ionic cap add android
ionic cap sync
```

### 4. **Auf Geräten testen**
```bash
ionic cap run ios --device
ionic cap run android --device
```

## 📋 Generated Project Structure

Nach der Ausführung wird folgende Projektstruktur erstellt:

```
MeinProjekt/
├── 📄 src/
│   ├── index.html              # Haupt-HTML
│   ├── sites/
│   │   └── protocol.html       # Protokoll-Seite
│   ├── js/                     # JavaScript Module
│   │   ├── app.js             # Haupt-App Logic
│   │   ├── chart.js           # Chart Komponente
│   │   ├── weather.js         # Wetter Module
│   │   └── ...
│   ├── styles/
│   │   └── style.css          # Custom Styles
│   └── assets/
│       └── icons/             # App Icons
├── 📱 ios/                     # iOS Platform
├── 🤖 android/                 # Android Platform
├── 📦 package.json             # Dependencies
├── ⚙️ capacitor.config.ts      # Capacitor Config
├── 🔧 ionic.config.json        # Ionic Config
├── 📝 README.md                # Projekt-Dokumentation
└── 🔨 scripts/                 # Helper Scripts
```

## 🎨 UI Components

Das generierte Projekt enthält:

### 📊 **Dashboard Cards**
- 🌤️ **Wetter Card** - Temperatur und Umgebungsdaten
- 📏 **Messungen Card** - Aktuelle Messwerte
- 📈 **Statistiken Card** - 24h Übersicht
- 📊 **Chart Card** - Verlaufsdiagramm

### 🎛️ **Navigation**
- **Tab Bar** - Dashboard, Messungen, Protokoll, Einstellungen
- **Action Buttons** - Export, Sync, Transfer
- **FAB** - Quick Actions

### 📱 **Mobile Features**
- **iOS Design** - Native iOS Look & Feel
- **Android Material** - Material Design Komponenten
- **Responsive** - Optimiert für alle Bildschirmgrößen
- **Touch Gestures** - Mobile-optimierte Interaktionen

## 🔍 Troubleshooting

### ❌ **Häufige Probleme**

**Problem**: Ansible nicht gefunden
```bash
# Lösung: Ansible installieren
pip3 install --user ansible
# oder
brew install ansible  # macOS
```

**Problem**: Node.js Fehler
```bash
# Lösung: Node.js aktualisieren
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

**Problem**: Ionic CLI fehlt
```bash
# Lösung: Ionic global installieren
npm install -g @ionic/cli
```

**Problem**: Permission Denied
```bash
# Lösung: Berechtigungen setzen
chmod +x scripts/*.sh
sudo chown -R $USER:$USER .
```

### 🔧 **Debug Commands**
```bash
# Ansible Syntax Check
ansible-playbook playbook.yml --syntax-check

# Inventory überprüfen
ansible-inventory -i inventory.yml --list

# Tasks auflisten
ansible-playbook playbook.yml --list-tasks

# Variables anzeigen
ansible-playbook playbook.yml --list-hosts
```

## 📚 Documentation Links

- 📖 [Ansible Documentation](https://docs.ansible.com/)
- ⚡ [Ionic Framework](https://ionicframework.com/docs)
- 📱 [Capacitor](https://capacitorjs.com/docs)
- 🎨 [Ionic UI Components](https://ionicframework.com/docs/components)

## 🤝 Contributing

### 🔧 **Development**
1. Fork das Repository
2. Feature Branch erstellen: `git checkout -b feature/amazing-feature`
3. Changes committen: `git commit -m 'Add amazing feature'`
4. Push to Branch: `git push origin feature/amazing-feature`
5. Pull Request öffnen

### 🐛 **Bug Reports**
Bitte erstelle ein Issue mit:
- Ansible Version
- OS Information
- Error Messages
- Steps to Reproduce

### 💡 **Feature Requests**
Gerne neue Features vorschlagen über GitHub Issues!

## 📄 License

MIT License - siehe [LICENSE](LICENSE) für Details.

## 🙏 Credits

- **Ionic Framework** - Cross-platform mobile development
- **Capacitor** - Native mobile runtime
- **Ansible** - Automation platform
- **Chart.js** - Data visualization

---

## 🎉 Happy Mobile Development!

Erstellt mit ❤️ von der iOS/Android Generator Community

**Version**: 2.0.0  
**Last Updated**: Juli 2025  
**Supported Platforms**: iOS 12+, Android 6+, Modern Browsers