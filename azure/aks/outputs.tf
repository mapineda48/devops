output "aks_cluster_name" {
  value       = azurerm_kubernetes_cluster.aks.name
  description = "Nombre del cluster AKS"
}

output "aks_resource_group" {
  value       = azurerm_resource_group.rg.name
  description = "Resource group del cluster"
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}
