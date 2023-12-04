# Hub Virtual Network
resource "azurerm_virtual_network" "aks" {
  name                = "vnet-${var.prefix}-${var.stage}"
  location            = var.location
  resource_group_name = azurerm_resource_group.playground.name
  address_space       = ["10.10.0.0/16"]
  tags                = local.common_tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# Spoke Subnet for Azure PaaS Services
resource "azurerm_subnet" "aks_nodes" {
  name                 = "snet-${var.prefix}-${var.stage}-aks-nodes"
  resource_group_name  = azurerm_resource_group.playground.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.10.8.0/21"]
}

# Spoke Subnet for Azure PaaS Services
resource "azurerm_subnet" "aks_pods" {
  name                 = "snet-${var.prefix}-${var.stage}-aks-pods"
  resource_group_name  = azurerm_resource_group.playground.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.10.16.0/21"]
  delegation {
    name = "aks-delegation"
    service_delegation {
      name    = "Microsoft.ContainerService/managedClusters"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}