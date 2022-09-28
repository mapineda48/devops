resource "random_pet" "prefix" {}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "${random_pet.prefix.id}-rg"
  location = "eastus"

  tags = {
    environment = "Demo"
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "${random_pet.prefix.id}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${random_pet.prefix.id}-k8s"

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

  network_profile {
    network_plugin = "azure"
  }

  service_principal {
    client_id     = var.appId
    client_secret = var.password
  }

  role_based_access_control {
    enabled = true
  }

  tags = {
    environment = "Demo"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "window" {
  name                  = "win"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.default.id
  node_count            = 1
  vm_size               = "Standard_DS2_v2"
  os_disk_size_gb       = 30
  os_type               = "Windows" # Default is Linux, we can change to Windows

  tags = {
    Environment = "Demo Windows"
  }
}
