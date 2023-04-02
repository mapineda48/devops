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
