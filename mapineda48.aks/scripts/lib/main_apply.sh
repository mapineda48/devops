main_apply() {
    log "Terraform init..."
    tf_init

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
}