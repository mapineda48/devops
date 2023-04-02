# # https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/godaddy.md

# resource "kubernetes_namespace" "external_dns" {
#   metadata {
#     name = "external-dns"
#   }
# }

# resource "kubernetes_service_account" "external_dns" {
#   metadata {
#     name = "external-dns"
#   }
# }

# resource "kubernetes_cluster_role" "external_dns" {
#   metadata {
#     name = "external-dns"
#   }

#   rule {
#     api_groups = [""]
#     resources  = ["services"]
#     verbs      = ["get", "watch", "list"]
#   }

#   rule {
#     api_groups = [""]
#     resources  = ["pods"]
#     verbs      = ["get", "watch", "list"]
#   }

#   rule {
#     api_groups = ["extensions", "networking.k8s.io"]
#     resources  = ["ingresses"]
#     verbs      = ["get", "watch", "list"]
#   }

#   rule {
#     api_groups = [""]
#     resources  = ["nodes"]
#     verbs      = ["list", "watch"]
#   }

#   rule {
#     api_groups = [""]
#     resources  = ["endpoints"]
#     verbs      = ["get", "watch", "list"]
#   }
# }

# resource "kubernetes_cluster_role_binding" "external_dns_viewer" {
#   metadata {
#     name = "external-dns-viewer"
#   }

#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role.external_dns.metadata[0].name
#   }

#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account.external_dns.metadata[0].name
#     namespace = "default"
#   }
# }

# resource "kubernetes_deployment" "external_dns" {
#   metadata {
#     name      = "external-dns"
#     namespace = "default"
#   }

#   spec {
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
#         service_account_name = kubernetes_service_account.external_dns.metadata[0].name

#         container {
#           name  = "external-dns"
#           image = "registry.k8s.io/external-dns/external-dns:v0.13.4"

#           args = [
#             "--source=ingress",
#             "--source=service",
#             "--domain-filter=${var.godaddy_domain}",
#             "--provider=godaddy",
#             "--txt-prefix=external-dns.",
#             "--txt-owner-id=mapineda48",
#             "--godaddy-api-key=${var.godaddy_api_key}",
#             "--godaddy-api-secret=${var.godaddy_api_secret}",
#           ]
#         }
#       }
#     }

#     strategy {
#       type = "Recreate"
#     }
#   }
# }
