variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-mapineda48-core"
}

variable "storage_account_tier" {
  description = "Tier of the storage account"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
}

variable "dns_zone_name" {
  description = "Name of the DNS zone"
  type        = string
  default     = "mapineda48.de"
}

variable "dns_www_target" {
  description = "Target CNAME for www subdomain (e.g., username.github.io)"
  type        = string
  default     = "mapineda48.github.io"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
