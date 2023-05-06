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
  principal_id                     = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  role_definition_id               = data.azurerm_role_definition.acr_pull.id
  scope                            = azurerm_container_registry.default.id
  skip_service_principal_aad_check = true
}

resource "null_resource" "apply_k8s_manifiest" {
  count = var.apply_k8s_manifiest ? 1 : 0

  depends_on = [
    azurerm_container_registry.default,
    azurerm_kubernetes_cluster.default,
    azurerm_role_assignment.acr_role_assignment
  ]

  provisioner "local-exec" {
    when       = create
    on_failure = continue

    command = "cd ${path.module}/k8s && bash apply.sh"

    environment = {
      CLUSTER_ISSUER_CERT = var.cluster_issuer_cert
      GODADDY_API_KEY     = var.godaddy_api_key
      GODADDY_API_SECRET  = var.godaddy_api_secret
      GODADDY_DOMAIN      = var.godaddy_domain
      ACR_LOGIN           = var.acr_name
      KUBECONFIG_CONTENTS = azurerm_kubernetes_cluster.default.kube_config_raw
    }
  }
}

resource "null_resource" "destroy_k8s_manifiest" {
  count = length(null_resource.apply_k8s_manifiest)

  depends_on = [
    azurerm_container_registry.default,
    azurerm_kubernetes_cluster.default,
    azurerm_role_assignment.acr_role_assignment
  ]

  triggers = {
    api_key    = var.godaddy_api_key
    api_secret = var.godaddy_api_secret
    domain     = var.godaddy_domain
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue

    command = "bash ${path.module}/k8s/delete_godaddy_records.sh"

    environment = {
      API_KEY     = self.triggers.api_key
      API_SECRET  = self.triggers.api_secret
      DOMAIN      = self.triggers.domain
    }
  }
}