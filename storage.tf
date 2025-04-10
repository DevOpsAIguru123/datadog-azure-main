################################
# Storage Account              #
################################

resource "azurerm_storage_account" "storage_account" {
  name                     = format("stddlogfwd%s", random_string.id.result)
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  
  # Enable hierarchical namespace for Data Lake Storage Gen2
  is_hns_enabled = false

  # Disable public network access for enhanced security
  public_network_access_enabled = false
  
  # Network rules to lock down access
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
    ip_rules       = []
    virtual_network_subnet_ids = []
  }
  
  tags = local.common_tags
}

################################
# Storage Private DNS Zones    #
################################

# Private DNS Zone for Blob Storage
resource "azurerm_private_dns_zone" "blob_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob_dns_link" {
  name                  = "dnslink-blob-001"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.blob_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Private DNS Zone for File Storage
resource "azurerm_private_dns_zone" "file_dns_zone" {
  name                = "privatelink.file.core.windows.net"
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "file_dns_link" {
  name                  = "dnslink-file-001"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.file_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Private DNS Zone for Queue Storage
resource "azurerm_private_dns_zone" "queue_dns_zone" {
  name                = "privatelink.queue.core.windows.net"
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "queue_dns_link" {
  name                  = "dnslink-queue-001"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.queue_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.common_tags
}

# Private DNS Zone for Table Storage
resource "azurerm_private_dns_zone" "table_dns_zone" {
  name                = "privatelink.table.core.windows.net"
  resource_group_name = azurerm_resource_group.resource_group.name
  tags                = local.common_tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "table_dns_link" {
  name                  = "dnslink-table-001"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.table_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = local.common_tags
}

################################
# Storage Private Endpoints    #
################################

# Private endpoint for Blob Storage
resource "azurerm_private_endpoint" "blob_endpoint" {
  name                = "pep-blob-001"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  subnet_id           = azurerm_subnet.private_endpoints_subnet.id
  
  private_service_connection {
    name                           = "psc-pep-blob-001"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }
  
  private_dns_zone_group {
    name                 = "pdnszg-pep-blob-001"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob_dns_zone.id]
  }
  
  tags = local.common_tags
}

# Private endpoint for File Storage
resource "azurerm_private_endpoint" "file_endpoint" {
  name                = "pep-file-001"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  subnet_id           = azurerm_subnet.private_endpoints_subnet.id
  
  private_service_connection {
    name                           = "psc-pep-file-001"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["file"]
  }
  
  private_dns_zone_group {
    name                 = "pdnszg-pep-file-001"
    private_dns_zone_ids = [azurerm_private_dns_zone.file_dns_zone.id]
  }
  
  tags = local.common_tags
}

# Private endpoint for Queue Storage
resource "azurerm_private_endpoint" "queue_endpoint" {
  name                = "pep-queue-001"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  subnet_id           = azurerm_subnet.private_endpoints_subnet.id
  
  private_service_connection {
    name                           = "psc-pep-queue-001"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["queue"]
  }
  
  private_dns_zone_group {
    name                 = "pdnszg-pep-queue-001"
    private_dns_zone_ids = [azurerm_private_dns_zone.queue_dns_zone.id]
  }
  
  tags = local.common_tags
}

# Private endpoint for Table Storage
resource "azurerm_private_endpoint" "table_endpoint" {
  name                = "pep-table-001"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  subnet_id           = azurerm_subnet.private_endpoints_subnet.id
  
  private_service_connection {
    name                           = "psc-pep-table-001"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    is_manual_connection           = false
    subresource_names              = ["table"]
  }
  
  private_dns_zone_group {
    name                 = "pdnszg-pep-table-001"
    private_dns_zone_ids = [azurerm_private_dns_zone.table_dns_zone.id]
  }
  
  tags = local.common_tags
} 