az_set_kubecontext() {
  az aks get-credentials -g "$AKS_RG" -n "$AKS_NAME" --overwrite-existing
  kubectl cluster-info
}