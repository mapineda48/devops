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