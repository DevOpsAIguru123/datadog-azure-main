#################################
# Virtual Network Configuration #
#################################

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = format("vnet-dd-log-forwarder-%s", random_string.id.result)
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = [var.vnet_address_space]
  tags                = local.common_tags
}

# Subnet for Private Endpoints
resource "azurerm_subnet" "private_endpoints_subnet" {
  name                                      = "snet-private-endpoints"
  resource_group_name                       = azurerm_resource_group.resource_group.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = [var.private_endpoints_subnet_prefix]
  private_endpoint_network_policies         = "Enabled"
}

# Subnet for Function App outbound traffic
resource "azurerm_subnet" "function_app_subnet" {
  name                 = "snet-function-app"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.function_app_subnet_prefix]
  delegation {
    name = "function-app-delegation"
    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Private DNS Zone for Function App
resource "azurerm_private_dns_zone" "function_dns_zone" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "function_dns_link" {
  name                  = "dnslink-function-001"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.function_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.common_tags
} 