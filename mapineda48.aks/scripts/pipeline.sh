#!/usr/bin/env bash

set -euo pipefail
source "$(dirname "$0")/common.sh"
source "$(dirname "$0")/aks_helpers.sh"

: "${TF_WORKDIR:?missing}"  # exige variable
cd "$TF_WORKDIR"

ACTION="${ACTION:-auto}"
if [[ "$ACTION" == "auto" ]]; then
  HOUR=$(TZ="America/Bogota" date +"%H")
  log "Auto mode. Colombia hour: $HOUR"
  if [[ "$HOUR" == "07" ]]; then
    ACTION="apply"
  elif (( 10#$HOUR >= 19 )); then
    ACTION="destroy"
  else
    log "Not the right time (auto). Exit."
    exit 0
  fi
fi
log "Resolved ACTION: $ACTION"

# Backend opcional si usas hcl
[[ -f backend.hcl ]] || {
  log "No backend.hcl, skipping backend config file creation."
}

terraform init -backend-config=backend.hcl
terraform plan

# Credenciales Velero (no imprime contenido)
cat > credentials-velero <<EOF
AZURE_SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID}
AZURE_TENANT_ID=${AZURE_TENANT_ID}
AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
AZURE_RESOURCE_GROUP=${BACKEND_RG}
AZURE_CLOUD_NAME=AzurePublicCloud
EOF

IFS=',' read -ra NS_LIST <<< "${BACKUP_NAMESPACES:-cert-manager,ingress-nginx,default}"
NS_ARGS=()
for ns in "${NS_LIST[@]}"; do NS_ARGS+=(--include-namespaces "$ns"); done

if [[ "$ACTION" == "apply" ]]; then
  log "Terraform apply..."
  terraform apply -auto-approve

  log "Reading TF outputs..."
  get_tf_outputs

  log "Set kube context..."
  set_kubecontext

  log "Install ingress-nginx..."
  install_ingress_nginx

  log "Install external-dns..."
  install_external_dns

  log "Install cert-manager..."
  install_cert_manager

  # Velero opcional
  # log "Ensure Velero..."
  # install_velero_server

  # Restore opcional
  # LATEST_BACKUP=$(velero backup get -o json | jq -r \
  #   --arg pfx "${VELERO_BACKUP_PREFIX:-cm-backup}" \
  #   '.items | map(select(.metadata.name|startswith($pfx))) | sort_by(.status.startTimestamp) | last?.metadata.name // empty')
  # if [[ -n "$LATEST_BACKUP" ]]; then
  #   log "Restoring $LATEST_BACKUP ..."
  #   velero restore create --from-backup "$LATEST_BACKUP" --wait || true
  # fi

  log "Apply done."
elif [[ "$ACTION" == "destroy" ]]; then
  # Opcional: backup previo
  # if terraform output -json >/dev/null 2>&1; then
  #   get_tf_outputs || true
  #   set_kubecontext || true
  #   install_velero_server || true
  #   TS=$(date +%Y%m%d%H%M%S)
  #   BACKUP_NAME="${VELERO_BACKUP_PREFIX:-cm-backup}-${TS}"
  #   log "Creating Velero backup: $BACKUP_NAME"
  #   velero backup create "$BACKUP_NAME" "${NS_ARGS[@]}" --wait || true
  # fi

  log "Terraform destroy..."
  terraform destroy -auto-approve
  log "Destroy done."
else
  fatal "Unknown ACTION: $ACTION"
fi
