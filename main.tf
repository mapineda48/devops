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
# Blob Containers
# -----------------------------------------------------------------------------
resource "azurerm_storage_container" "main" {
  name                  = "data-${random_string.container_suffix.result}"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Public container (private access - only accessible via CDN)
resource "azurerm_storage_container" "public" {
  name                  = "public"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# Azure Front Door Profile (Modern CDN replacement)
# -----------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_profile" "main" {
  count               = var.dns_zone_name != null ? 1 : 0
  name                = "afd-${var.resource_group_name}"
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard_AzureFrontDoor"
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Front Door Origin Group
# -----------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_origin_group" "main" {
  count                    = var.dns_zone_name != null ? 1 : 0
  name                     = "storage-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    protocol            = "Https"
    interval_in_seconds = 100
    request_type        = "HEAD"
    path                = "/"
  }
}

# -----------------------------------------------------------------------------
# Front Door Origin (Storage Account)
# -----------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_origin" "main" {
  count                         = var.dns_zone_name != null ? 1 : 0
  name                          = "storage-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main[0].id

  enabled                        = true
  host_name                      = azurerm_storage_account.main.primary_blob_host
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = azurerm_storage_account.main.primary_blob_host
  priority                       = 1
  weight                         = 1000
  certificate_name_check_enabled = true
}

# -----------------------------------------------------------------------------
# Front Door Endpoint
# -----------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_endpoint" "main" {
  count                    = var.dns_zone_name != null ? 1 : 0
  name                     = "cdn-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id
  tags                     = var.tags
}

# -----------------------------------------------------------------------------
# Front Door Route
# -----------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_route" "main" {
  count                         = var.dns_zone_name != null ? 1 : 0
  name                          = "storage-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main[0].id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main[0].id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.main[0].id]

  # Link the route to the custom domain
  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.cdn[0].id]

  supported_protocols    = ["Http", "Https"]
  patterns_to_match      = ["/*"]
  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = true
  https_redirect_enabled = true
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

# -----------------------------------------------------------------------------
# DNS CNAME Record for CDN subdomain
# -----------------------------------------------------------------------------
resource "azurerm_dns_cname_record" "cdn" {
  count               = var.dns_zone_name != null ? 1 : 0
  name                = "cdn"
  zone_name           = azurerm_dns_zone.main[0].name
  resource_group_name = azurerm_resource_group.main.name
  ttl                 = 3600
  record              = azurerm_cdn_frontdoor_endpoint.main[0].host_name
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# Front Door Custom Domain with Managed HTTPS
# -----------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_custom_domain" "cdn" {
  count                    = var.dns_zone_name != null ? 1 : 0
  name                     = "cdn-custom-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main[0].id
  dns_zone_id              = azurerm_dns_zone.main[0].id
  host_name                = "cdn.${var.dns_zone_name}"

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

# -----------------------------------------------------------------------------
# Front Door Custom Domain Association
# -----------------------------------------------------------------------------
resource "azurerm_cdn_frontdoor_custom_domain_association" "cdn" {
  count                          = var.dns_zone_name != null ? 1 : 0
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.cdn[0].id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.main[0].id]
}
