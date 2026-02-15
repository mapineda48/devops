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

resource "random_string" "deploy_container_suffix" {
  length  = 8
  special = false
  upper   = false
  numeric = true
}

resource "random_string" "servicebus_namespace_suffix" {
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
# Service Bus Namespace (Basic - lowest cost)
# -----------------------------------------------------------------------------
resource "azurerm_servicebus_namespace" "main" {
  name                = "sb-mapineda48-${random_string.servicebus_namespace_suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  sku                 = "Basic"
  minimum_tls_version = "1.2"

  tags = var.tags
}

# -----------------------------------------------------------------------------
# Service Bus Queue: VPS control plane
# -----------------------------------------------------------------------------
resource "azurerm_servicebus_queue" "vps_control" {
  name         = "vps-control"
  namespace_id = azurerm_servicebus_namespace.main.id

  # Keep defaults minimal for Basic tier.
}

# Separate policies for least-privilege (send vs listen)
resource "azurerm_servicebus_queue_authorization_rule" "vps_control_sender" {
  name     = "vps-control-sender"
  queue_id = azurerm_servicebus_queue.vps_control.id

  listen = false
  send   = true
  manage = false
}

resource "azurerm_servicebus_queue_authorization_rule" "vps_control_listener" {
  name     = "vps-control-listener"
  queue_id = azurerm_servicebus_queue.vps_control.id

  listen = true
  send   = false
  manage = false
}

# -----------------------------------------------------------------------------
# Storage Account
# Security configuration:
# - TLS 1.2 minimum (Azure requires 1.2+ starting Aug 2025)
# - No public blob access allowed (blobs remain private)
# - Versioning enabled for data protection
# - Soft delete enabled for recovery
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
  https_traffic_only_enabled      = true

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
# Blob Containers
# -----------------------------------------------------------------------------
resource "azurerm_storage_container" "main" {
  name                  = "data-${random_string.container_suffix.result}"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Dedicated deploy container for VM runtime artifacts (certs, acme, etc.)
resource "azurerm_storage_container" "deploy" {
  name                  = "data-${random_string.deploy_container_suffix.result}"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Public container - kept private for security
# Access should be controlled via SAS tokens or Azure AD authentication
resource "azurerm_storage_container" "public" {
  name                  = "public"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# Cloudflare DNS Zone (optional - only created if cloudflare_zone_name is provided)
# -----------------------------------------------------------------------------
resource "cloudflare_zone" "main" {
  count = var.cloudflare_zone_name != null ? 1 : 0
  account = {
    id = var.cloudflare_account_id
  }
  name = var.cloudflare_zone_name
  type = "full"
}

# CNAME record for www subdomain in Cloudflare
resource "cloudflare_dns_record" "www" {
  count   = var.cloudflare_zone_name != null && var.dns_www_target != null ? 1 : 0
  zone_id = cloudflare_zone.main[0].id
  name    = "www"
  type    = "CNAME"
  content = var.dns_www_target
  ttl     = 3600
  proxied = false
  comment = "Managed by Terraform - points to external site"
}

# CNAME record for CDN subdomain pointing to Azure Blob Storage
# Cloudflare will act as CDN/proxy for the storage account
resource "cloudflare_dns_record" "cdn" {
  count   = var.cloudflare_zone_name != null ? 1 : 0
  zone_id = cloudflare_zone.main[0].id
  name    = "cdn"
  type    = "CNAME"
  content = azurerm_storage_account.main.primary_blob_host
  ttl     = 1 # TTL of 1 = Automatic when proxied
  proxied = true
  comment = "Managed by Terraform - CDN for Azure Blob Storage"
}
