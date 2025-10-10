aks_install_cert_manager() {
  log "Installing cert-manager ${CERT_MANAGER_VERSION:?missing}"
  kubectl apply -f "https://github.com/cert-manager/cert-manager/releases/download/${CERT_MANAGER_VERSION}/cert-manager.crds.yaml"
  helm repo add jetstack https://charts.jetstack.io --force-update
  helm upgrade --install cert-manager jetstack/cert-manager \
    --namespace cert-manager --create-namespace --version "${CERT_MANAGER_VERSION}"
}