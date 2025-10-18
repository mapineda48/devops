variable "resource_group_name" {
  description = "Nombre del resource group"
  type        = string
  default	  = "mapineda48-aks"
}

variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "eastus"
}

variable "aks_cluster_name" {
  description = "Nombre del cluster AKS"
  type        = string
  default     = "aks-ephemeral"
}

variable "dns_prefix" {
  description = "Prefijo DNS para el API server de AKS"
  type        = string
  default     = "aksdemo"
}
