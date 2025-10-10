# Requiere: TF in $TF_WORKDIR

tf_get_outputs() {
  AKS_NAME="$(terraform -chdir="${TF_WORKDIR}" output -raw aks_cluster_name)"
  AKS_RG="$(terraform -chdir="${TF_WORKDIR}" output -raw aks_resource_group)"
  export AKS_NAME AKS_RG
  log "AKS_NAME=$AKS_NAME AKS_RG=$AKS_RG"
}