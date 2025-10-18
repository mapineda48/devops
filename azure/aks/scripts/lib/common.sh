
# Activa -x solo si exportas DEBUG=1 (para no filtrar secretos por error)
[[ "${DEBUG:-}" == "1" ]] && set -x

log()   { printf "%s %s\n" "$(date +'%F %T')" "$*" >&2; }
fatal() { log "ERROR: $*"; exit 1; }

# Limpieza automática si algo falla
cleanup() { :; }  # agrega aquí rm de temporales si quieres
trap cleanup EXIT
