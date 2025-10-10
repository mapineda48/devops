main_destroy() {
    log "Terraform init..."
    tf_init

    log "Terraform destroy..."
    terraform destroy -auto-approve
    
    log "Destroy done."
}