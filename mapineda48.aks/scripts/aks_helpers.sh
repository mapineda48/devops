#!/usr/bin/env bash
# aks_helpers.sh
set -euo pipefail
source "$(dirname "$0")/common.sh"

# Requiere: TF in $TF_WORKDIR
get_tf_outputs() {
  AKS_NAME="$(terraform -chdir="${TF_WORKDIR}" output -raw aks_cluster_name)"
  AKS_RG="$(terraform -chdir="${TF_WORKDIR}" output -raw aks_resource_group)"
  export AKS_NAME AKS_RG
  log "AKS_NAME=$AKS_NAME AKS_RG=$AKS_RG"
}

set_kubecontext() {
  az aks get-credentials -g "$AKS_RG" -n "$AKS_NAME" --overwrite-existing
  kubectl cluster-info
}

install_ingress_nginx() {
  log "Installing ingress-nginx"
  helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update
  local verArgs=()
  [[ -n "${INGRESS_NGINX_CHART_VERSION:-}" ]] && verArgs+=(--version "$INGRESS_NGINX_CHART_VERSION")

  helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx --create-namespace "${verArgs[@]}" \
    --set controller.ingressClassResource.name=nginx \
    --set controller.ingressClass=nginx \
    --set controller.replicaCount=1 \
    --set controller.nodeSelector."kubernetes\\.io/os"=linux \
    --set defaultBackend.nodeSelector."kubernetes\\.io/os"=linux

  log "Waiting for ingress-nginx to be available..."
  kubectl -n ingress-nginx wait --for=condition=available deploy/ingress-nginx-controller --timeout=300s
}

install_external_dns() {
  log "Installing external-dns (official chart)"
  helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/ --force-update

  local verArgs=()
  [[ -n "${EXTERNALDNS_CHART_VERSION:-}" ]] && verArgs+=(--version "$EXTERNALDNS_CHART_VERSION")

  # Auth por Workload Identity (recomendado) o por Client Secret (rápido).
  local authArgs=()
  if [[ "${USE_WORKLOAD_IDENTITY:-false}" == "true" ]]; then
    : "${AKS_WORKLOAD_CLIENT_ID:?missing}"
    : "${AZURE_SUBSCRIPTION_ID:?missing}"
    : "${AZURE_TENANT_ID:?missing}"
    : "${BACKEND_RG:?missing}"

    authArgs+=(
      --set azure.useWorkloadIdentityAuth=true
      --set azure.subscriptionId="${AZURE_SUBSCRIPTION_ID}"
      --set azure.tenantId="${AZURE_TENANT_ID}"
      --set azure.resourceGroup="${BACKEND_RG}"
      --set serviceAccount.annotations."azure\.workload\.identity/client-id"="${AKS_WORKLOAD_CLIENT_ID}"
    )
  else
    : "${AZURE_SUBSCRIPTION_ID:?missing}"
    : "${AZURE_TENANT_ID:?missing}"
    : "${AZURE_CLIENT_ID:?missing}"
    : "${AZURE_CLIENT_SECRET:?missing}"
    : "${BACKEND_RG:?missing}"

    # Sin WI: pasamos credenciales por variables de entorno (extraEnv)
    authArgs+=(
      --set azure.useWorkloadIdentityAuth=false
      --set azure.subscriptionId="${AZURE_SUBSCRIPTION_ID}"
      --set azure.tenantId="${AZURE_TENANT_ID}"
      --set azure.resourceGroup="${BACKEND_RG}"
      --set extraEnv[0].name=AZURE_SUBSCRIPTION_ID --set extraEnv[0].value="${AZURE_SUBSCRIPTION_ID}"
      --set extraEnv[1].name=AZURE_TENANT_ID       --set extraEnv[1].value="${AZURE_TENANT_ID}"
      --set extraEnv[2].name=AZURE_CLIENT_ID       --set extraEnv[2].value="${AZURE_CLIENT_ID}"
      --set extraEnv[3].name=AZURE_CLIENT_SECRET   --set extraEnv[3].value="${AZURE_CLIENT_SECRET}"
    )
  fi

  : "${AKS_NAME:?missing}"
  : "${AZURE_DNS_ZONE:?missing}"

  helm upgrade --install external-dns external-dns/external-dns \
    --namespace external-dns --create-namespace "${verArgs[@]}" \
    --set provider=azure \
    --set policy=sync \
    --set registry=txt \
    --set "txtOwnerId=${AKS_NAME}" \
    --set "sources={ingress,service}" \
    --set "domainFilters={${AZURE_DNS_ZONE}}" \
    --set interval=1m \
    --set resources.requests.cpu="100m" \
    --set resources.requests.memory="128Mi" \
    --set resources.limits.cpu="300m" \
    --set resources.limits.memory="256Mi" \
    "${authArgs[@]}"

  kubectl -n external-dns rollout status deploy/external-dns --timeout=180s || true
}


install_cert_manager() {
  log "Installing cert-manager ${CERT_MANAGER_VERSION:?missing}"
  kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.crds.yaml"
  helm repo add jetstack https://charts.jetstack.io --force-update
  helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager --create-namespace --version "${CERT_MANAGER_VERSION}"
}

# Velero opcional
install_velero_server() {
  log "Installing Velero CLI"
  curl -sSL "https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz" -o /tmp/velero.tgz
  tar -xzf /tmp/velero.tgz -C /tmp
  sudo mv "/tmp/velero-${VELERO_VERSION}-linux-amd64/velero" /usr/local/bin/velero
  velero version

  log "Installing/Ensuring Velero server"
  velero install \
    --provider azure \
    --plugins "${VELERO_PLUGIN_AZURE:?missing}" \
    --bucket "${BACKEND_CONTAINER_VELERO:?missing}" \
    --secret-file ./credentials-velero \
    --backup-location-config resourceGroup="${BACKEND_RG:?missing}",storageAccount="${BACKEND_STORAGE_ACCOUNT:?missing}" \
    --use-restic \
    --wait || true

  kubectl -n velero rollout status deploy/velero --timeout=180s || true
}
