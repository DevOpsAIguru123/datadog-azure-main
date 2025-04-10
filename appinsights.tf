#####################################
# Log Analytics and App Insights #
#####################################

# Create Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = format("law-dd-log-forwarder-%s", random_string.id.result)
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = local.common_tags
}

# Create Application Insights connected to Log Analytics
resource "azurerm_application_insights" "app_insights" {
  name                = format("appi-dd-log-forwarder-%s", random_string.id.result)
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.log_analytics.id
  
  tags = local.common_tags
}


# Outputs to be used in other modules
output "app_insights_connection_string" {
  value     = azurerm_application_insights.app_insights.connection_string
  sensitive = true
}

output "app_insights_instrumentation_key" {
  value     = azurerm_application_insights.app_insights.instrumentation_key
  sensitive = true
}

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace"
  value = azurerm_log_analytics_workspace.log_analytics.id
} 