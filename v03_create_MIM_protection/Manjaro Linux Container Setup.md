# Manjaro Linux Container Setup

## Übersicht
Dieses Setup enthält einen Podman-Container mit Manjaro Linux und ein Login-Skript für einfachen Zugriff.

## Dateien
- `login.sh` - Skript zum Einloggen in den Manjaro Container
- `README_Manjaro_Container.md` - Diese Anweisungsdatei

## Container-Details
- **Container Name:** manjaro-container
- **Base Image:** docker.io/manjarolinux/base:latest
- **Shell:** /bin/bash

## Verwendung

### Container starten und einloggen
```bash
./login.sh
```

Das Skript führt automatisch folgende Schritte aus:
1. Prüft ob der Container existiert
2. Startet den Container falls er nicht läuft
3. Öffnet eine interaktive Bash-Shell im Container

### Manuelle Container-Verwaltung

#### Container starten
```bash
podman start manjaro-container
```

#### In Container einloggen
```bash
podman exec -it manjaro-container /bin/bash
```

#### Container stoppen
```bash
podman stop manjaro-container
```

#### Container-Status prüfen
```bash
podman ps -a
```

#### Container löschen (falls gewünscht)
```bash
podman rm manjaro-container
```

## Hinweise
- Der Container läuft nach dem Login weiterhin im Hintergrund
- Zum Beenden der Container-Session: `exit` eingeben
- Zum vollständigen Stoppen des Containers: `podman stop manjaro-container`
- Alle Änderungen im Container bleiben erhalten, solange der Container nicht gelöscht wird

## Troubleshooting
- Falls Probleme auftreten, prüfen Sie den Container-Status mit `podman ps -a`
- Bei Fehlern können Sie den Container neu erstellen mit:
  ```bash
  podman rm manjaro-container
  podman create --name manjaro-container -it docker.io/manjarolinux/base /bin/bash
  ```

