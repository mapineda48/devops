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

output "servicebus_namespace_name" {
  description = "Name of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.name
}

output "servicebus_namespace_id" {
  description = "ID of the Service Bus namespace"
  value       = azurerm_servicebus_namespace.main.id
}

output "servicebus_namespace_endpoint" {
  description = "Service Bus namespace endpoint"
  value       = azurerm_servicebus_namespace.main.endpoint
}

output "container_name" {
  description = "Name of the data blob container"
  value       = azurerm_storage_container.main.name
}

output "deploy_container_name" {
  description = "Name of the dedicated deploy blob container"
  value       = azurerm_storage_container.deploy.name
}

output "public_container_name" {
  description = "Name of the public blob container (private access - use SAS tokens)"
  value       = azurerm_storage_container.public.name
}

# Cloudflare Outputs
output "cloudflare_zone_id" {
  description = "Cloudflare Zone ID (if created)"
  value       = var.cloudflare_zone_name != null ? cloudflare_zone.main[0].id : null
}

output "cloudflare_zone_name" {
  description = "Cloudflare Zone Name (if created)"
  value       = var.cloudflare_zone_name != null ? cloudflare_zone.main[0].name : null
}

output "cloudflare_zone_name_servers" {
  description = "Cloudflare name servers for zone (if created)"
  value       = var.cloudflare_zone_name != null ? cloudflare_zone.main[0].name_servers : null
}

output "cloudflare_zone_status" {
  description = "Cloudflare zone status (if created)"
  value       = var.cloudflare_zone_name != null ? cloudflare_zone.main[0].status : null
}

output "cloudflare_cdn_url" {
  description = "Cloudflare CDN URL for Azure Blob Storage (if created)"
  value       = var.cloudflare_zone_name != null ? "https://cdn.${var.cloudflare_zone_name}" : null
}

output "cloudflare_worker_name" {
  description = "Cloudflare Worker script name (if created)"
  value       = var.cloudflare_zone_name != null ? cloudflare_workers_script.sas_gateway[0].script_name : null
}

output "cdn_example_url" {
  description = "Example URL to test CDN access to public container"
  value       = var.cloudflare_zone_name != null ? "https://cdn.${var.cloudflare_zone_name}/public/<blob-name>" : null
}
