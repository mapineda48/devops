output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "storage_account_primary_access_key" {
  description = "Primary access key of the storage account"
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "container_name" {
  description = "Name of the blob container"
  value       = azurerm_storage_container.main.name
}

output "public_container_name" {
  description = "Name of the public blob container (accessible only via CDN)"
  value       = azurerm_storage_container.public.name
}

output "dns_zone_name" {
  description = "Name of the DNS zone (if created)"
  value       = var.dns_zone_name != null ? azurerm_dns_zone.main[0].name : null
}

output "dns_zone_id" {
  description = "ID of the DNS zone (if created)"
  value       = var.dns_zone_name != null ? azurerm_dns_zone.main[0].id : null
}

output "dns_zone_name_servers" {
  description = "Name servers for the DNS zone (if created)"
  value       = var.dns_zone_name != null ? azurerm_dns_zone.main[0].name_servers : null
}

output "dns_www_fqdn" {
  description = "FQDN of the www CNAME record (if created)"
  value       = var.dns_zone_name != null && var.dns_www_target != null ? azurerm_dns_cname_record.www[0].fqdn : null
}

output "cdn_frontdoor_profile_id" {
  description = "ID of the Azure Front Door profile (if created)"
  value       = var.dns_zone_name != null ? azurerm_cdn_frontdoor_profile.main[0].id : null
}

output "cdn_endpoint_url" {
  description = "Default Azure Front Door endpoint URL (if created)"
  value       = var.dns_zone_name != null ? "https://${azurerm_cdn_frontdoor_endpoint.main[0].host_name}" : null
}

output "cdn_custom_domain_url" {
  description = "Custom domain CDN URL (if created)"
  value       = var.dns_zone_name != null ? "https://cdn.${var.dns_zone_name}" : null
}

output "cdn_custom_domain_validation_token" {
  description = "Validation token for custom domain (if created)"
  value       = var.dns_zone_name != null ? azurerm_cdn_frontdoor_custom_domain.cdn[0].validation_token : null
  sensitive   = true
}
