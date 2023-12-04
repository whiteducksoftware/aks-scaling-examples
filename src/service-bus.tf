resource "azurerm_servicebus_namespace" "order_processor" {
  name                = "sb-${var.prefix}-${var.stage}-orders"
  location            = var.location
  resource_group_name = azurerm_resource_group.playground.name
  sku                 = "Standard"
  tags                = local.common_tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_servicebus_queue" "order_processor" {
  name                = "orders"
  namespace_id        = azurerm_servicebus_namespace.order_processor.id
  enable_partitioning = true
}
