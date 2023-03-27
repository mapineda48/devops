# # https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/godaddy.md

# data "terraform_remote_state" "kubernetes" {
#   backend = "local"

#   config = {
#     path = "/home/mapineda48/repo/devops/terraform/Full/terraform.tfstate"
#   }
# }

# provider "kubernetes" {
#   host = "${azurerm_kubernetes_cluster.default.kube_config[0].host}"

#   client_certificate     = base64decode(azurerm_kubernetes_cluster.default.kube_config[0].client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.default.kube_config[0].client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.default.kube_config[0].cluster_ca_certificate)
# }

# resource "kubernetes_deployment" "external_dns" {
#   metadata {
#     name = "external-dns"
#   }

#   spec {
#     strategy {
#       type = "Recreate"
#     }

#     selector {
#       match_labels = {
#         app = "external-dns"
#       }
#     }

#     template {
#       metadata {
#         labels = {
#           app = "external-dns"
#         }
#       }

#       spec {
#         container {
#           name  = "external-dns"
#           image = "registry.k8s.io/external-dns/external-dns:v0.13.2"
#           args = [
#             "--source=service",
#             "--domain-filter=${var.godaddy_domain}",
#             "--provider=godaddy",
#             "--txt-prefix=external-dns.",
#             "--txt-owner-id=owner-id",
#             "--godaddy-api-key=${var.godaddy_api_key}",
#             "--godaddy-api-secret=${var.godaddy_api_secret}",
#           ]
#         }
#       }
#     }
#   }
# }
