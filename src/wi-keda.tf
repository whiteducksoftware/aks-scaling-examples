resource "azurerm_user_assigned_identity" "order_processor" {
  name                = "order-processor"
  location            = azurerm_resource_group.playground.location
  resource_group_name = azurerm_resource_group.playground.name
  tags                = local.common_tags

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "azurerm_federated_identity_credential" "order_processor_keda_sa" {
  name                = "order-processor-keda-sa"
  resource_group_name = azurerm_resource_group.playground.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.aks.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.order_processor.id
  subject             = "system:serviceaccount:kube-system:keda-operator"
}

resource "azurerm_role_assignment" "order_processor" {
  scope                            = azurerm_servicebus_namespace.order_processor.id
  role_definition_name             = "Azure Service Bus Data Receiver"
  principal_id                     = azurerm_user_assigned_identity.order_processor.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "order_processor_owner" {
  scope                            = azurerm_servicebus_namespace.order_processor.id
  role_definition_name             = "Azure Service Bus Data Owner"
  principal_id                     = azurerm_user_assigned_identity.order_processor.principal_id
  skip_service_principal_aad_check = true
}