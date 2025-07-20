#!/bin/bash

# Manjaro Linux Container Erstellungs-Skript
# Dieses Skript erstellt einen neuen Manjaro Container mit Podman

CONTAINER_NAME="manjaro-container"
IMAGE_NAME="docker.io/manjarolinux/base:latest"

echo "=== Manjaro Linux Container Erstellen ==="
echo "Container Name: $CONTAINER_NAME"
echo "Image: $IMAGE_NAME"
echo

# Prüfen ob der Container bereits existiert
if podman container exists "$CONTAINER_NAME"; then
    echo "⚠️  Container '$CONTAINER_NAME' existiert bereits!"
    echo
    echo "Optionen:"
    echo "1. Container löschen und neu erstellen: podman rm $CONTAINER_NAME"
    echo "2. Bestehenden Container verwenden: ./login.sh"
    echo
    read -p "Möchten Sie den bestehenden Container löschen und neu erstellen? (j/N): " response
    if [[ "$response" =~ ^[Jj]$ ]]; then
        echo "Lösche bestehenden Container..."
        podman rm -f "$CONTAINER_NAME"
        if [ $? -eq 0 ]; then
            echo "✅ Container erfolgreich gelöscht!"
        else
            echo "❌ Fehler beim Löschen des Containers!"
            exit 1
        fi
    else
        echo "Vorgang abgebrochen. Verwenden Sie ./login.sh um den bestehenden Container zu nutzen."
        exit 0
    fi
fi

echo "Lade Manjaro Linux Image herunter (falls noch nicht vorhanden)..."
podman pull "$IMAGE_NAME"
if [ $? -ne 0 ]; then
    echo "❌ Fehler beim Herunterladen des Images!"
    exit 1
fi

echo
echo "Erstelle Container '$CONTAINER_NAME'..."
podman create --name "$CONTAINER_NAME" -it "$IMAGE_NAME" /bin/bash

if [ $? -eq 0 ]; then
    echo "✅ Container '$CONTAINER_NAME' erfolgreich erstellt!"
    echo
    
    # Login-Skript ausführbar machen
    if [ -f "login.sh" ]; then
        echo "Mache login.sh ausführbar..."
        chmod +x login.sh
        if [ $? -eq 0 ]; then
            echo "✅ login.sh ist jetzt ausführbar!"
        else
            echo "⚠️  Warnung: Konnte login.sh nicht ausführbar machen!"
        fi
    else
        echo "⚠️  Warnung: login.sh nicht gefunden!"
    fi
    
    echo
    echo "Container-Setup abgeschlossen! 🐧"
    echo
    echo "Möchten Sie jetzt direkt in den Container einloggen?"
    read -p "Container starten und einloggen? (J/n): " login_response
    
    if [[ "$login_response" =~ ^[Nn]$ ]]; then
        echo "Container wurde erstellt. Verwenden Sie './login.sh' zum Einloggen."
    else
        echo "Starte Container und logge ein..."
        if [ -f "login.sh" ]; then
            ./login.sh
        else
            echo "⚠️  login.sh nicht gefunden! Verwende manuellen Login..."
            podman start "$CONTAINER_NAME" && podman exec -it "$CONTAINER_NAME" /bin/bash
        fi
    fi
    
    echo
    echo "Alternative manuelle Befehle:"
    echo "- Container starten: podman start $CONTAINER_NAME"
    echo "- In Container einloggen: podman exec -it $CONTAINER_NAME /bin/bash"
    echo "- Container stoppen: podman stop $CONTAINER_NAME"
    
else
    echo "❌ Fehler beim Erstellen des Containers!"
    exit 1
fi