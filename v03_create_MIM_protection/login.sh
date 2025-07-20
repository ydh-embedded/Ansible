#!/bin/bash

# Manjaro Linux Container Login Script
# Dieses Skript startet den Manjaro Container und öffnet eine interaktive Shell

CONTAINER_NAME="manjaro-container"

echo "=== Manjaro Linux Container Login ==="
echo "Container Name: $CONTAINER_NAME"
echo

# Prüfen ob der Container existiert
if ! podman container exists "$CONTAINER_NAME"; then
    echo "Fehler: Container '$CONTAINER_NAME' existiert nicht!"
    echo "Bitte stellen Sie sicher, dass der Container korrekt erstellt wurde."
    exit 1
fi

# Container-Status prüfen
CONTAINER_STATUS=$(podman inspect --format='{{.State.Status}}' "$CONTAINER_NAME")
echo "Container Status: $CONTAINER_STATUS"

# Container starten falls er nicht läuft
if [ "$CONTAINER_STATUS" != "running" ]; then
    echo "Starte Container..."
    podman start "$CONTAINER_NAME"
    if [ $? -eq 0 ]; then
        echo "Container erfolgreich gestartet!"
    else
        echo "Fehler beim Starten des Containers!"
        exit 1
    fi
else
    echo "Container läuft bereits."
fi

echo
echo "Verbinde mit Manjaro Linux Container..."
echo "Zum Beenden der Session: 'exit' eingeben"
echo "=========================================="
echo

# In den Container einloggen
podman exec -it "$CONTAINER_NAME" /bin/bash

echo
echo "Container-Session beendet."
echo "Container läuft weiterhin im Hintergrund."
echo "Zum Stoppen des Containers: podman stop $CONTAINER_NAME"

