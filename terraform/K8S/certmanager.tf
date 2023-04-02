# https://registry.terraform.io/modules/terraform-iaac/cert-manager/kubernetes/2.5.0

module "cert_manager" {
  source        = "terraform-iaac/cert-manager/kubernetes"

  cluster_issuer_email                   = "${var.cluster_issuer_email}"
  cluster_issuer_name                    = "cert-manager-global"
  cluster_issuer_private_key_secret_name = "cert-manager-private-key"
}