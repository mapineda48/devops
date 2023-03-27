data "azurerm_role_definition" "acr_pull" {
  name = "AcrPull"
}

resource "azurerm_resource_group" "default" {
  name     = "${var.project_name}-rg"
  location = "eastus"

  tags = {
    environment = "Development"
  }
}

resource "azurerm_container_registry" "default" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  sku                 = "Basic"

  admin_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "Development"
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster
resource "azurerm_kubernetes_cluster" "default" {
  name                = "${var.project_name}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${var.project_name}-k8s"

  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = "Development"
  }
}

resource "azurerm_role_assignment" "acr_role_assignment" {
  scope              = azurerm_container_registry.default.id
  role_definition_id = data.azurerm_role_definition.acr_pull.id
  principal_id       = azurerm_kubernetes_cluster.default.identity[0].principal_id
}














###########################


# provider "kubernetes" {
#   host = azurerm_kubernetes_cluster.default.kube_config[0].host

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
