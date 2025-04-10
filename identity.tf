################################
# User-Assigned Managed Identity #
################################

resource "azurerm_user_assigned_identity" "function_identity" {
  name                = format("id-dd-log-forwarder-%s", random_string.id.result)
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  tags                = local.common_tags
} 