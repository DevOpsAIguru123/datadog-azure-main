################################
# Key Vault                  #
################################

resource "azurerm_key_vault" "key_vault" {
  name                        = format("kv-ddlf-%s", random_string.id.result)
  location                    = var.location
  resource_group_name         = azurerm_resource_group.resource_group.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  enable_rbac_authorization   = true
  
  # Disable public network access for enhanced security
  public_network_access_enabled = false
  network_acls {
    default_action             = "Deny"
    bypass                     = "AzureServices"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
  
  tags = local.common_tags
}

################################
# Key Vault Private DNS       #
################################

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_dns_link" {
  name                  = "dnslink-keyvault-001"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.common_tags
}

################################
# Key Vault Private Endpoint  #
################################

# Private endpoint for Key Vault
resource "azurerm_private_endpoint" "keyvault_endpoint" {
  name                = "pep-keyvault-001"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  subnet_id           = azurerm_subnet.private_endpoints_subnet.id

  private_service_connection {
    name                           = "psc-keyvault-001"
    private_connection_resource_id = azurerm_key_vault.key_vault.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "pdnszg-keyvault-001"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault_dns_zone.id]
  }
  
  tags = local.common_tags
}

################################
# Key Vault Access            #
################################

# Get current client configuration
data "azurerm_client_config" "current" {}

# Grant Function App access to Key Vault
resource "azurerm_role_assignment" "function_keyvault_role" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.function_identity.principal_id
}

# Grant current user admin access to Key Vault for management
resource "azurerm_role_assignment" "current_user_keyvault_admin" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# The Key Vault secret section has been removed since we'll be manually adding the secret
