# Resource Group
output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.resource_group.name
}

# Virtual Network
output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the virtual network"
  value       = azurerm_virtual_network.vnet.name
}

output "private_endpoints_subnet_id" {
  description = "The ID of the private endpoints subnet"
  value       = azurerm_subnet.private_endpoints_subnet.id
}

output "function_app_subnet_id" {
  description = "The ID of the function app subnet"
  value       = azurerm_subnet.function_app_subnet.id
}

# Storage Account
output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.storage_account.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.storage_account.name
}

# Event Hub
output "event_hub_namespace_id" {
  description = "The ID of the Event Hub Namespace"
  value       = azurerm_eventhub_namespace.event_hub_namespace.id
}

output "event_hub_namespace_name" {
  description = "The name of the Event Hub Namespace"
  value       = azurerm_eventhub_namespace.event_hub_namespace.name
}

output "event_hub_id" {
  description = "The ID of the Event Hub"
  value       = azurerm_eventhub.eventhub.id
}

output "event_hub_name" {
  description = "The name of the Event Hub"
  value       = azurerm_eventhub.eventhub.name
}

# Function App
output "function_app_id" {
  description = "The ID of the Function App"
  value       = azurerm_windows_function_app.function_app.id
}

output "function_app_name" {
  description = "The name of the Function App"
  value       = azurerm_windows_function_app.function_app.name
}

output "function_app_hostname" {
  description = "The default hostname of the Function App"
  value       = azurerm_windows_function_app.function_app.default_hostname
}

# App Insights
output "app_insights_id" {
  description = "The ID of the Application Insights instance"
  value       = azurerm_application_insights.app_insights.id
}

output "app_insights_app_id" {
  description = "The App ID of the Application Insights instance"
  value       = azurerm_application_insights.app_insights.app_id
} 