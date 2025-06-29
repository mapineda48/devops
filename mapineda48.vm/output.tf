output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
  description = "Dirección IP pública de la VM para conexión SSH"
}

output "vm_fqdn" {
  value = "${var.dns_subdomain}.${var.dns_zone_name}"
  description = "Subdominio apuntando a la VM"
}
