# provider "azurerm" {
#   features {}
# }

# resource "azurerm_resource_group" "example" {
#   name     = "imedicaldev"
#   location = "East US"
# }

# resource "azurerm_container_registry" "example" {
#   name                = "imedicaldevacr"
#   resource_group_name = azurerm_resource_group.example.name
#   location            = azurerm_resource_group.example.location
#   sku                 = "Basic"

#   admin_enabled = true
# }

provider "azurerm" {
  features {}
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "example-aks-cluster"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "example-aks-dns"

  agent_pool_profile {
    name            = "default"
    count           = 1
    vm_size         = "Standard_DS2_v2"
    os_type         = "Linux"
    vnet_subnet_id  = data.azurerm_subnet.example.id
  }

  service_principal {
    client_id     = ""
    client_secret = ""
  }

  tags = {
    Environment = "Test"
  }
}

data "azurerm_resource_group" "example" {
  name = "example-resource-group"
}

data "azurerm_subnet" "example" {
  name                = "example-subnet"
  virtual_network_name = "example-vnet"
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "random_string" "password" {
  length  = 16
  special = true
}

resource "azurerm_user_assigned_identity" "example" {
  name                = "example-identity"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_kubernetes_cluster.example.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.example.principal_id
}

module "example" {
  source              = "Azure/kubernetes-engine/azurerm"
  version             = "2.0.1"
  resource_group_name = data.azurerm_resource_group.example.name
  location            = data.azurerm_resource_group.example.location
  cluster_name        = azurerm_kubernetes_cluster.example.name
  dns_prefix          = azurerm_kubernetes_cluster.example.dns_prefix
  ssh_public_key      = file("~/.ssh/id_rsa.pub")
  service_principal   = {
    client_id     = azurerm_user_assigned_identity.example.client_id
    client_secret = random_string.password.result
  }
}
