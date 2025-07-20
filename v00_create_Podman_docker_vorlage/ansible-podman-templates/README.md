# Ansible Podman Container Templates

Wiederverwendbare Ansible-Templates für Podman-Container-Projekte mit automatischem Login-Script.

## 🚀 Quick-Start

```bash
# 1. Repository klonen/erstellen
./setup-ansible-project.sh

# 2. Dependencies installieren
make install

# 3. Erstes Projekt deployen
make deploy PROJECT=mcp-server

# 4. In Container einloggen
make login PROJECT=mcp-server
```

## 📁 Struktur

```
ansible-podman-templates/
├── Makefile                    # Build-Automatisierung
├── quick-start.sh             # Schnellstart-Script
├── ansible/
│   ├── site.yml               # Haupt-Playbook
│   ├── ansible.cfg            # Ansible-Konfiguration
│   ├── inventory/             # Host-Inventar
│   ├── vars/                  # Projekt-Variablen
│   │   ├── common.yml         # Gemeinsame Variablen
│   │   ├── mcp-server.yml     # MCP-Server Projekt
│   │   ├── web-app.yml        # Web-App Projekt
│   │   └── api-service.yml    # API-Service Projekt
│   └── roles/                 # Ansible-Rollen
│       ├── podman_setup/      # Podman-Installation
│       ├── container_project/ # Container-Deployment
│       └── monitoring/        # Monitoring-Setup
└── examples/                  # Beispiel-Projekte
```

## 🛠️ Verfügbare Kommandos

### Projekt-Management
```bash
make deploy PROJECT=my-project     # Projekt deployen
make destroy PROJECT=my-project    # Projekt entfernen
make status PROJECT=my-project     # Projekt-Status
make login PROJECT=my-project      # Container-Login
```

### Entwicklung
```bash
make validate                      # Ansible-Syntax prüfen
make dev PROJECT=my-project        # Development-Deployment
make prod PROJECT=my-project       # Production-Deployment
make test                         # Test-Deployment
```

### Wartung
```bash
make clean                        # Container-Cleanup
make list                         # Alle Projekte auflisten
make examples                     # Beispiel-Projekte erstellen
```

## 📋 Neues Projekt erstellen

### 1. Projekt-Variablen definieren

Erstellen Sie `ansible/vars/mein-projekt.yml`:

```yaml
project_name: "mein-projekt"
project_description: "Mein Custom Projekt"
container_name: "{{ project_name }}-container"
container_image: "{{ project_name }}:latest"

container_config:
  ports:
    - "3000:3000"
  volumes:
    - "{{ project_base_dir }}/{{ project_name }}/data:/app/data"
  environment:
    NODE_ENV: "development"

dockerfile_config:
  base_image: "node:18-alpine"
  working_dir: "/app"
  exposed_ports:
    - "3000"
```

### 2. Projekt deployen

```bash
make deploy PROJECT=mein-projekt
```

### 3. Container verwenden

```bash
# In Container einloggen
make login PROJECT=mein-projekt

# Status prüfen
make status PROJECT=mein-projekt
```

## 🔧 Konfiguration

### Container-Konfiguration

Jedes Projekt wird durch eine YAML-Datei in `ansible/vars/` konfiguriert:

- **project_name**: Eindeutiger Projekt-Name
- **container_config**: Container-spezifische Einstellungen
- **dockerfile_config**: Dockerfile-Generierung
- **services**: Service-Definitionen

### Ansible-Rollen

- **podman_setup**: Installiert und konfiguriert Podman
- **container_project**: Erstellt Container-Projekt mit allen Scripts
- **monitoring**: Optionales Monitoring-Setup

## 📦 Generierte Dateien

Für jedes Projekt werden automatisch erstellt:

```
~/ansible-projects/PROJECT_NAME/
├── login.sh              # 🔐 Container-Login
├── manage.sh             # 🛠️ Container-Management
├── build.sh              # 🔨 Container-Build
├── deploy.sh             # 🚀 Container-Deploy
├── cleanup.sh            # 🧹 Cleanup
├── container/
│   ├── Dockerfile        # Container-Definition
│   ├── requirements.txt  # Dependencies
│   └── app files...      # Anwendungs-Dateien
├── configs/              # Konfigurationsdateien
├── data/                 # Persistente Daten
└── logs/                 # Log-Dateien
```

## 🔐 Login-Script Features

Das generierte `login.sh` bietet:

- **Interaktive Shell**: Bash, Python, Root
- **Container-Status**: Live-Informationen
- **Prozess-Übersicht**: Laufende Services
- **Log-Anzeige**: Container-Logs
- **Dateisystem-Browser**: Struktur-Übersicht

## 🌐 Web-Interfaces

Automatisch verfügbare Web-Services:

- **Monitoring**: Container-Status und Logs
- **Application**: Projekt-spezifische Services
- **Management**: Web-basierte Container-Verwaltung

## 🎯 Anwendungsfälle

### MCP-Server
```bash
make deploy PROJECT=mcp-server
# → MCP Inspector: http://localhost:6247
# → Streamlit Client: http://localhost:8501
```

### Web-Anwendung
```bash
make deploy PROJECT=web-app
# → Frontend: http://localhost:3000
# → Backend API: http://localhost:8000
```

### API-Service
```bash
make deploy PROJECT=api-service
# → API: http://localhost:8000
# → Admin: http://localhost:8080
```

## 🔄 Workflow

1. **Projekt definieren**: Variablen in `vars/` erstellen
2. **Deployen**: `make deploy PROJECT=name`
3. **Entwickeln**: `make login PROJECT=name`
4. **Testen**: Web-Interfaces nutzen
5. **Deployen**: Updates mit erneutem `make deploy`

## 🚨 Troubleshooting

### Container startet nicht
```bash
make status PROJECT=name
podman logs project-container
```

### Port-Konflikte
```bash
sudo netstat -tulpn | grep :PORT
```

### Ansible-Fehler
```bash
make validate
ansible-lint ansible/site.yml
```

## 🔧 Erweiterte Konfiguration

### Custom Dockerfile
Erstellen Sie `ansible/templates/custom-dockerfile.j2` und referenzieren Sie es in den Projekt-Variablen.

### Zusätzliche Services
Erweitern Sie die `services`-Liste in den Projekt-Variablen.

### Monitoring
Aktivieren Sie Monitoring mit `enable_monitoring: true`.

---

**Mit diesen Templates können Sie schnell neue Container-Projekte mit vollständiger Ansible-Automatisierung und Login-Funktionalität erstellen! 🚀**
