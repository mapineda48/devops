provider "azurerm" {
  features {}

  # En azurerm v4.x, subscription_id es recomendado explícitamente
  # Puedes configurarlo aquí o via variable de entorno ARM_SUBSCRIPTION_ID
  # subscription_id = var.subscription_id
}

provider "random" {}

# Cloudflare provider configuration
# Best practice: use CLOUDFLARE_API_TOKEN environment variable
# Create token at: https://dash.cloudflare.com/profile/api-tokens
provider "cloudflare" {
  # api_token is set via CLOUDFLARE_API_TOKEN env variable
  # Alternatively, uncomment below and use a variable:
  # api_token = var.cloudflare_api_token
}

# DigitalOcean provider configuration
# Best practice: use DIGITALOCEAN_TOKEN environment variable
provider "digitalocean" {}
