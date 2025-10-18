output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
  description = "Dirección IP pública de la VM para conexión SSH"
}

output "vm_fqdns" {
  value = [
    for subdomain in var.subdomains :
    "${subdomain}.${var.dns_zone_name}"
  ]
  description = "Lista de subdominios apuntando a la IP pública de la VM"
}
