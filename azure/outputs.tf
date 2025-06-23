output "resource_group_location" {
  value = azurerm_resource_group.mapineda48_rg.location
}

output "resource_group_name" {
  value = azurerm_resource_group.mapineda48_rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.mapineda48_storage.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.mapineda48_storage.primary_blob_endpoint
}

output "connection_string" {
  value     = azurerm_storage_account.mapineda48_storage.primary_connection_string
  sensitive = true
}

output "persistent_data_disk_id" {
  value = azurerm_managed_disk.persistent_data_disk.id
}

output "dns_zone_name" {
  description = "Nombre de la zona DNS configurada en Azure"
  value       = azurerm_dns_zone.mapineda48_zone.name
}

output "cdn_url" {
  value       = "https://${azurerm_cdn_endpoint.mapineda48_cdn_endpoint.name}.azureedge.net/"
  description = "CDN endpoint URL"
}
