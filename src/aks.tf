# create AKS
resource "azurerm_kubernetes_cluster" "aks" {
  name                      = "aks-${var.prefix}-${var.stage}"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.playground.name
  dns_prefix                = "aks-${var.prefix}-${var.stage}"
  kubernetes_version        = "1.27.7"
  local_account_disabled    = "true"
  tags                      = local.common_tags
  workload_identity_enabled = true
  oidc_issuer_enabled       = true

  azure_active_directory_role_based_access_control {
    managed                = true
    tenant_id              = data.azurerm_client_config.current.tenant_id
    admin_group_object_ids = ["429bfc0b-dac5-4dd8-862a-831985f20e4d"]
    azure_rbac_enabled     = true
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }

  auto_scaler_profile {

  }

  workload_autoscaler_profile {
    keda_enabled                    = true
    vertical_pod_autoscaler_enabled = true
  }

  default_node_pool {
    name                         = "nodepool1"
    node_count                   = 2
    vm_size                      = "Standard_D4ds_v5"
    os_sku                       = "AzureLinux"
    only_critical_addons_enabled = "true"
    os_disk_type                 = "Ephemeral"
    os_disk_size_gb              = "30"
    vnet_subnet_id               = azurerm_subnet.aks_nodes.id
    pod_subnet_id                = azurerm_subnet.aks_pods.id
    scale_down_mode              = "Delete"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "scale" {
  name                  = "nodepool2"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D4ds_v5"
  node_count            = 1
  min_count             = 1
  max_count             = 10
  os_sku                = "AzureLinux"
  os_disk_type          = "Ephemeral"
  os_disk_size_gb       = "30"
  enable_auto_scaling   = true
  vnet_subnet_id        = azurerm_subnet.aks_nodes.id
  pod_subnet_id         = azurerm_subnet.aks_pods.id
  tags                  = local.common_tags

  lifecycle {
    ignore_changes = [
      node_count,
      tags
    ]
  }
}


