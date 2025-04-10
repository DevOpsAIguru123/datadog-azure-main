#######################
# Create Function App #
#######################

# App service plan
resource "azurerm_service_plan" "app_service_plan" {
  name                = format("asp-dd-log-forwarder-%s", random_string.id.result)
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  os_type             = "Windows"
  sku_name            = "EP1"
  tags                = local.common_tags
}

# Function app
resource "azurerm_windows_function_app" "function_app" {
  name                = format("fa-dd-log-forwarder-%s", random_string.id.result)
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  service_plan_id     = azurerm_service_plan.app_service_plan.id
  
  # Has Key Vault reference, so depends on role assignment
  depends_on = [
    azurerm_role_assignment.function_keyvault_role
  ]
  
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"                    = "1",
    "FUNCTIONS_WORKER_RUNTIME"                    = "node",
    "AzureWebJobsDisableHomepage"                 = "true",
    "WEBSITE_NODE_DEFAULT_VERSION"                = "~20",
    "EventHubConnection__credential"              = "managedidentity",
    "EventHubConnection__fullyQualifiedNamespace" = format("%s.servicebus.windows.net", azurerm_eventhub_namespace.event_hub_namespace.name),
    "DD_API_KEY"                                  = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.key_vault.name};SecretName=datadog-api-key)",
    "DD_SITE"                                     = var.datadog_site,
    # Application Insights settings
    "APPLICATIONINSIGHTS_CONNECTION_STRING"       = azurerm_application_insights.app_insights.connection_string,
    "APPINSIGHTS_INSTRUMENTATIONKEY"              = azurerm_application_insights.app_insights.instrumentation_key,
    "ApplicationInsightsAgent_EXTENSION_VERSION"  = "~3",
    # User assigned managed identity client ID
    "AZURE_CLIENT_ID"                             = azurerm_user_assigned_identity.function_identity.client_id
  }
  site_config {}
  storage_account_name          = azurerm_storage_account.storage_account.name
  storage_uses_managed_identity = true
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.function_identity.id]
  }
  public_network_access_enabled = false
  virtual_network_subnet_id     = azurerm_subnet.function_app_subnet.id
  tags                          = local.common_tags
}

#######################
# Function App Network #
#######################

# Private endpoint for Function app
resource "azurerm_private_endpoint" "function_endpoint" {
  name                = "pep-function-001"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  subnet_id           = azurerm_subnet.private_endpoints_subnet.id
  
  private_service_connection {
    name                           = "psc-function-001"
    private_connection_resource_id = azurerm_windows_function_app.function_app.id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }
  
  private_dns_zone_group {
    name                 = "pdnszg-function-001"
    private_dns_zone_ids = [azurerm_private_dns_zone.function_dns_zone.id]
  }
  
  tags = local.common_tags
}

#######################
# Role Assignments    #
#######################

# Role Assignment for storage account
resource "azurerm_role_assignment" "storage_role_assignment" {
  scope                = azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.function_identity.principal_id
}

# Role Assignment for event hub
resource "azurerm_role_assignment" "eventhub_role_assignment" {
  scope                = azurerm_eventhub_namespace.event_hub_namespace.id
  role_definition_name = "Azure Event Hubs Data Owner"
  principal_id         = azurerm_user_assigned_identity.function_identity.principal_id
}

#######################
# Zip Deploy Function #
#######################

locals {
  functions_dir     = "${path.module}/functions"
  function_json     = templatefile("${local.functions_dir}/dd-log-forwarder/function.json", { event_hub_name = azurerm_eventhub.eventhub.name })
  index_js          = file("${local.functions_dir}/dd-log-forwarder/index.js")
  host_json         = file("${local.functions_dir}/host.json")
  functions_zip     = "${path.module}/functions.zip"
}

# Create zip folder with functions
data "archive_file" "functions_zip" {
  type        = "zip"
  output_path = local.functions_zip
  source {
    content  = local.function_json
    filename = "dd-log-forwarder/function.json"
  }
  source {
    content  = local.index_js
    filename = "dd-log-forwarder/index.js"
  }
  source {
    content  = local.host_json
    filename = "host.json"
  }
}

# Publish code to function app
locals {
  allow_public_access_command = "az functionapp update --resource-group ${azurerm_resource_group.resource_group.name} -n ${azurerm_windows_function_app.function_app.name} --set publicNetworkAccess=Enabled siteConfig.publicNetworkAccess=Enabled"
  publish_code_command        = "az webapp deploy --resource-group ${azurerm_resource_group.resource_group.name} --name ${azurerm_windows_function_app.function_app.name} --src-path ${data.archive_file.functions_zip.output_path}"
  deny_public_access_command  = "az functionapp update --resource-group ${azurerm_resource_group.resource_group.name} -n ${azurerm_windows_function_app.function_app.name} --set publicNetworkAccess=Disabled siteConfig.publicNetworkAccess=Disabled"
}

resource "null_resource" "function_app_publish" {
  depends_on = [
    data.archive_file.functions_zip, 
    azurerm_role_assignment.storage_role_assignment, 
    azurerm_role_assignment.eventhub_role_assignment,
    azurerm_windows_function_app.function_app,
    azurerm_user_assigned_identity.function_identity
  ]
  
  triggers = {
    input_json                  = data.archive_file.functions_zip.output_base64sha256
    publish_code_command        = local.publish_code_command
    allow_public_access_command = local.allow_public_access_command
    deny_public_access_command  = local.deny_public_access_command
  }
  
  provisioner "local-exec" {
    command = local.allow_public_access_command
  }
  
  provisioner "local-exec" {
    command = local.publish_code_command
  }
  
  provisioner "local-exec" {
    command = local.deny_public_access_command
  }
} 