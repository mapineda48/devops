# -----------------------------------------------------------------------------
# Random Strings for Unique Names
# Storage account names must be 3-24 characters, lowercase letters and numbers only
# Container names must be 3-63 characters, lowercase letters, numbers and hyphens
# -----------------------------------------------------------------------------
resource "random_string" "storage_account_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

resource "random_string" "container_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

# -----------------------------------------------------------------------------
# Resource Group
# -----------------------------------------------------------------------------
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# Storage Account
# -----------------------------------------------------------------------------
resource "azurerm_storage_account" "main" {
  name                     = "st${random_string.storage_account_suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type

  # Security best practices
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    versioning_enabled       = true
    last_access_time_enabled = true
    change_feed_enabled      = true

    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Blob Container
# -----------------------------------------------------------------------------
resource "azurerm_storage_container" "main" {
  name                  = "data-${random_string.container_suffix.result}"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# DNS Zone (optional - only created if dns_zone_name is provided)
# -----------------------------------------------------------------------------
resource "azurerm_dns_zone" "main" {
  count               = var.dns_zone_name != null ? 1 : 0
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# DNS CNAME Record for www subdomain (optional)
# -----------------------------------------------------------------------------
resource "azurerm_dns_cname_record" "www" {
  count               = var.dns_zone_name != null && var.dns_www_target != null ? 1 : 0
  name                = "www"
  zone_name           = azurerm_dns_zone.main[0].name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600
  record              = var.dns_www_target
  tags                = var.tags
}
