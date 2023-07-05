resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
  # sensitive        = true

  lifecycle {
    ignore_changes = [result]
  }
}

data "azurerm_role_definition" "acr_pull" {
  name = "AcrPull"
}

resource "azurerm_resource_group" "default" {
  name     = "${var.project_name}-rg"
  location = "eastus"

  tags = {
    environment = "Development"
  }
}

resource "azurerm_container_registry" "default" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  sku                 = "Basic"

  admin_enabled = true

  identity {
    type = "SystemAssigned"
  }

  tags = {
    environment = "Development"
  }
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster
resource "azurerm_kubernetes_cluster" "default" {
  name                = "${var.project_name}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${var.project_name}-k8s"

  default_node_pool {
    name       = "agentpool"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  linux_profile {
    admin_username = "ubuntu"

    ssh_key {
      key_data = file(var.ssh_public_key)
    }
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true



  tags = {
    environment = "Development"
  }

  # Windows Settings
  dynamic "windows_profile" {
    for_each = var.win_admin_username != "" ? [1] : [] # Conditional Block - Experimental
    content {
      admin_username = var.win_admin_username
      admin_password = random_password.password.result
    }
  }

  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster#network_plugin
  network_profile {
    network_plugin = var.win_admin_username != "" ? "azure" : "kubenet"
  }
}


resource "azurerm_kubernetes_cluster_node_pool" "window" {
  count = var.win_admin_username != "" ? 1 : 0
  name                  = "win"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.default.id
  node_count            = 1
  vm_size               = "Standard_D4s_v3"
  os_disk_size_gb       = 35
  os_type               = "Windows"     # Default is Linux, we can change to Windows
  os_sku                = "Windows2019" # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool#os_sku

  node_taints = [                       # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool#node_taints
    "OS=Windows:NoSchedule"
  ]

  tags = {
    Environment = "Demo Windows"
  }
}

resource "azurerm_role_assignment" "acr_role_assignment" {
  principal_id                     = azurerm_kubernetes_cluster.default.kubelet_identity[0].object_id
  role_definition_id               = data.azurerm_role_definition.acr_pull.id
  scope                            = azurerm_container_registry.default.id
  skip_service_principal_aad_check = true
}

# Optional K8s Manifiest - Personal Testing Settings - Experimental

locals {
  secret_json    = "${path.module}/k8s/secret.json"
  template_json  = "${path.module}/k8s/template.json"
  k8s_apply      = fileexists(local.secret_json)
  k8s_secret     = local.k8s_apply ? jsondecode(file(local.secret_json)) : jsondecode(file(local.template_json))
}

resource "null_resource" "apply_k8s_manifiest" {
  count = local.k8s_apply ? 1 : 0

  depends_on = [
    azurerm_container_registry.default,
    azurerm_kubernetes_cluster.default,
    azurerm_role_assignment.acr_role_assignment
  ]

  provisioner "local-exec" {
    when       = create
    on_failure = continue

    command = "cd ${path.module}/k8s && bash apply.sh"

    environment = {
      ACR_LOGIN           = var.acr_name
      KUBECONFIG_CONTENTS = azurerm_kubernetes_cluster.default.kube_config_raw
      CLUSTER_ISSUER_CERT = local.k8s_secret.cluster_issuer_cert
      GODADDY_API_KEY     = local.k8s_secret.godaddy_api_key
      GODADDY_API_SECRET  = local.k8s_secret.godaddy_api_secret
      GODADDY_DOMAIN      = local.k8s_secret.godaddy_domain
    }
  }
}

resource "null_resource" "destroy_k8s_manifiest" {
  count = length(null_resource.apply_k8s_manifiest)

  depends_on = [
    azurerm_container_registry.default,
    azurerm_kubernetes_cluster.default,
    azurerm_role_assignment.acr_role_assignment
  ]

  triggers = {
    api_key    = local.k8s_secret.godaddy_api_key
    api_secret = local.k8s_secret.godaddy_api_secret
    domain     = local.k8s_secret.godaddy_domain
  }

  provisioner "local-exec" {
    when       = destroy
    on_failure = continue

    command = "bash ${path.module}/k8s/delete_godaddy_records.sh"

    environment = {
      API_KEY    = self.triggers.api_key
      API_SECRET = self.triggers.api_secret
      DOMAIN     = self.triggers.domain
    }
  }
}
