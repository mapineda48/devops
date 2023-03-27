provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "mapineda48"
  location = "East US"
}

resource "azurerm_container_registry" "example" {
  name                = "mapineda48acr"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Basic"

  admin_enabled = true
}
