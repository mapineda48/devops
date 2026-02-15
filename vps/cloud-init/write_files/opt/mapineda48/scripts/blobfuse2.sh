#!/bin/bash
TIMEOUT=60  # segundos
elapsed=0

echo "Esperando que Blobfuse2 se monte (max ${TIMEOUT}s)..."
until systemctl is-active --quiet mapineda48-blobfuse2.service; do
    sleep 1
    ((elapsed++))
    if (( elapsed >= TIMEOUT )); then
    echo "ERROR: Tiempo agotado esperando blobfuse2"
    systemctl status mapineda48-blobfuse2.service
    exit 1
    fi
done

echo "OK: Blobfuse2 activo despues de ${elapsed}s"
