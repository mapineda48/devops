provider "azurerm" {
  features {}
}

resource "random_string" "mapineda48_storage" {
  length  = 64
  upper   = true
  lower   = true
  numeric = true
  special = false
}

# 🌍 Grupo de recursos
resource "azurerm_resource_group" "mapineda48_rg" {
  name     = "mapineda48-rg"
  location = "East US"
}

# 💾 Cuenta de almacenamiento
resource "azurerm_storage_account" "mapineda48_storage" {
  name                     = random_string.mapineda48_storage.result
  resource_group_name      = azurerm_resource_group.mapineda48_rg.name
  location                 = azurerm_resource_group.mapineda48_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# 🪣 Contenedor privado para estado
resource "azurerm_storage_container" "mapineda48_storage_tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.mapineda48_storage.id
  container_access_type = "private"
}

# 🪣 Contenedor público para CDN
resource "azurerm_storage_container" "public_container" {
  name                  = "public"
  storage_account_id    = azurerm_storage_account.mapineda48_storage.id
  container_access_type = "blob"
}

# 💽 Disco administrado adicional
resource "azurerm_managed_disk" "persistent_data_disk" {
  name                 = "mapineda48-data-disk"
  location             = azurerm_resource_group.mapineda48_rg.location
  resource_group_name  = azurerm_resource_group.mapineda48_rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32
}

# 🌐 Zona DNS
resource "azurerm_dns_zone" "mapineda48_zone" {
  name                = "mapineda48.de"
  resource_group_name = azurerm_resource_group.mapineda48_rg.name
}

# 🌍 Registro para www
resource "azurerm_dns_cname_record" "www_cname" {
  name                = "www"
  zone_name           = azurerm_dns_zone.mapineda48_zone.name
  resource_group_name = azurerm_resource_group.mapineda48_rg.name
  ttl                 = 3600
  record              = "mapineda48.github.io"
}

# 🚀 Perfil de CDN
resource "azurerm_cdn_profile" "mapineda48_cdn_profile" {
  name                = "mapineda48-cdn-profile"
  location            = azurerm_resource_group.mapineda48_rg.location
  resource_group_name = azurerm_resource_group.mapineda48_rg.name
  sku                 = "Standard_Microsoft"
}

# 📡 Endpoint de CDN apuntando al storage
resource "azurerm_cdn_endpoint" "mapineda48_cdn_endpoint" {
  name                = "mapineda48-cdn-endpoint"
  profile_name        = azurerm_cdn_profile.mapineda48_cdn_profile.name
  location            = azurerm_resource_group.mapineda48_rg.location
  resource_group_name = azurerm_resource_group.mapineda48_rg.name

  is_http_allowed     = false
  is_https_allowed    = true
  origin_host_header  = "${azurerm_storage_account.mapineda48_storage.name}.blob.core.windows.net"

  content_types_to_compress = [
    "text/html",
    "text/css",
    "application/javascript",
    "application/json"
  ]

  origin {
    name      = "storage-origin"
    host_name = "${azurerm_storage_account.mapineda48_storage.name}.blob.core.windows.net"
  }
}

# 📡 CNAME en zona DNS (cdn.mapineda48.de ➝ *.azureedge.net)
resource "azurerm_dns_cname_record" "cdn_custom_domain" {
  name                = "cdn"
  zone_name           = azurerm_dns_zone.mapineda48_zone.name
  resource_group_name = azurerm_resource_group.mapineda48_rg.name
  ttl                 = 3600
  record              = "${azurerm_cdn_endpoint.mapineda48_cdn_endpoint.name}.azureedge.net"
}


# 🌐 Registrar dominio personalizado en el endpoint del CDN
# ⚠️ Importante: El CNAME debe estar propagado antes de aplicar el recurso azurerm_cdn_custom_domain, o fallará.
resource "azurerm_cdn_endpoint_custom_domain" "cdn_custom_domain" {
  name            = "cdn-mapineda48-de"
  cdn_endpoint_id = azurerm_cdn_endpoint.mapineda48_cdn_endpoint.id
  host_name       = "cdn.mapineda48.de"

  cdn_managed_https {
    certificate_type = "Shared"
    protocol_type    = "ServerNameIndication"
  }

  depends_on = [azurerm_dns_cname_record.cdn_custom_domain]
}