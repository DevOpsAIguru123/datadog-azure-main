################################
# Event Hub Namespace & Hub    #
################################

resource "azurerm_eventhub_namespace" "event_hub_namespace" {
  name                        = format("evhns-dd-log-forwarder-%s", random_string.id.result)
  location                    = var.location
  resource_group_name         = azurerm_resource_group.resource_group.name
  sku                         = "Standard"
  capacity                    = 1
  
  # Network configuration with secured access
  public_network_access_enabled = false
  # network_rulesets {
  #   default_action = "Deny"
  #   trusted_service_access_enabled = true
  #   virtual_network_rule {
  #     subnet_id = azurerm_subnet.function_app_subnet.id
  #   }
  # }
  
  tags = local.common_tags
}

resource "azurerm_eventhub" "eventhub" {
  name                = format("evh-dd-log-forwarder-%s", random_string.id.result)
  namespace_name      = azurerm_eventhub_namespace.event_hub_namespace.name
  resource_group_name = azurerm_resource_group.resource_group.name
  partition_count     = 2
  message_retention   = 1
}

################################
# Event Hub Private DNS        #
################################

# Private DNS Zone for Event Hub
resource "azurerm_private_dns_zone" "eventhub_dns_zone" {
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "eventhub_dns_link" {
  name                  = "dnslink-eventhub-001"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.eventhub_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.common_tags
}

################################
# Event Hub Private Endpoint   #
################################

# Private endpoint for Event Hub Namespace
resource "azurerm_private_endpoint" "eventhub_endpoint" {
  name                = "pep-eventhub-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  subnet_id           = azurerm_subnet.private_endpoints_subnet.id

  private_service_connection {
    name                           = "psc-eventhub-001"
    private_connection_resource_id = azurerm_eventhub_namespace.event_hub_namespace.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  private_dns_zone_group {
    name                 = "pdnszg-eventhub-001"
    private_dns_zone_ids = [azurerm_private_dns_zone.eventhub_dns_zone.id]
  }
  
  tags = local.common_tags
} 