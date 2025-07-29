variable "resource_group_name_mapineda48" {
  description = "Nombre del grupo de recursos principal"
  default     = "mapineda48-rg"
  type        = string
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  default     = "mapineda48-vm-rg"
  type        = string
}

variable "resource_group_location" {
  description = "Localización del grupo de recursos"
  default     = "eastus"
  type        = string
}

variable "dns_zone_name" {
  description = "Nombre de la zona DNS"
  default     = "mapineda48.de"
  type        = string
}

variable "subdomains" {
  type    = list(string)
  default = ["agape-app", "vm-webhook"]
}

variable "SSH_PUBLIC_KEY" {
  type        = string
  default     = ""
  description = "Clave pública SSH"
}

variable "SOURCE_IP" {
  description = "My public IP for SSH connection"
  default     = ""
  type        = string
}

variable "STORAGE_ACCOUNTNAME" {
  description = "Azure Storage Account Name"
  type        = string
}

variable "STORAGE_ACCOUNTKEY" {
  description = "Azure Storage Account Key"
  type        = string
}