#!/usr/bin/env bash

set -euo pipefail

for f in "$(dirname "$0")"/lib/*.sh; do
  # Solo si el archivo existe y es legible
  [ -r "$f" ] && source "$f"
done


# DEVELOP_ENV="$(dirname "$0")/.env"

# log "Loading environment from $DEVELOP_ENV"

# #shellcheck disable=SC2046
# export $(grep -v '^#' "$DEVELOP_ENV" | xargs)

# : "${TF_WORKDIR:?missing}"  # exige variable
# cd "$TF_WORKDIR"

# terraform init -backend-config=backend.hcl

# terraform plan

# log "Terraform apply..."
# terraform apply -auto-approve

# log "Reading TF outputs..."
# get_tf_outputs

# log "Set kube context..."
# set_kubecontext

aks_delete_ns

# log "Install ingress-nginx..."
# install_ingress_nginx

# log "Install external-dns..."
# install_external_dns

# log "Install cert-manager..."
# install_cert_manager

# log "Apply done."

