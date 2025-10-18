main_apply() {
    log "Terraform init..."
    tf_init

    log "Terraform apply..."
    terraform apply -auto-approve

    log "Reading TF outputs..."
    tf_get_outputs

    log "Set kube context..."
    az_set_kubecontext

    log "Install ingress-nginx..."
    aks_install_ingress_nginx

    log "Install external-dns..."
    aks_install_external_dns

    log "Install cert-manager..."
    aks_install_cert_manager
}