aks_delete_ns() {
  log "⚠️  Esto eliminará TODO excepto los namespaces del sistema."
  for ns in $(kubectl get ns --no-headers | awk '{print $1}' | grep -vE '^(kube-|default$)'); do
    log "⚠️  Deleting namespace: $ns"
    kubectl delete ns "$ns" --wait=false || true
  done
}