tf_init() {
    terraform init -backend-config=backend.hcl
    terraform plan
}