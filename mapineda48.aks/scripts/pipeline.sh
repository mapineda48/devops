#!/usr/bin/env bash

set -euo pipefail

# 1️⃣ Cargar todas las funciones Bash del directorio lib/
for f in "$(dirname "$0")"/lib/*.sh; do
  [ -r "$f" ] && source "$f"
done



ACTION="${ACTION:-auto}"

if [[ "$ACTION" == "auto" ]]; then
  HOUR=$(TZ="America/Bogota" date +"%H")
  log "Auto mode. Colombia hour: $HOUR"
  if [[ "$HOUR" == "07" ]]; then
    ACTION="main_apply"
  elif (( 10#$HOUR >= 19 )); then
    ACTION="main_destroy"
  else
    log "Not the right time (auto). Exit."
    exit 0
  fi
fi

log "Resolved ACTION: $ACTION"

# 3️⃣ Ejecutar la función si existe
if declare -F "$ACTION" >/dev/null; then
  "$ACTION" "$@"  # pasa el resto de argumentos
else
  echo "❌ La función '$ACTION' no existe." >&2
  exit 1
fi


: "${TF_WORKDIR:?missing}"  # exige variable

cd "$TF_WORKDIR"