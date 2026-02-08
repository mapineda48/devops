provider "azurerm" {
  features {}

  # En azurerm v4.x, subscription_id es recomendado explícitamente
  # Puedes configurarlo aquí o via variable de entorno ARM_SUBSCRIPTION_ID
  # subscription_id = var.subscription_id
}

provider "random" {}
