variable "subscription_id" {
  description = "The Azure subscription ID."
  type = string
}

variable "location" {
  description = "The Azure Region in which all resources should be created."
  type        = string
  default     = "East US2"
}

variable "vnet_address_space" {
  description = "The address space that is used by the virtual network."
  type        = string
  default     = "10.0.0.0/24"
}

variable "private_endpoints_subnet_prefix" {
  description = "The address prefix for the private endpoints subnet."
  type        = string
  default     = "10.0.0.0/27"
}

variable "function_app_subnet_prefix" {
  description = "The address prefix for the function app subnet."
  type        = string
  default     = "10.0.0.32/27"
}

variable "datadog_api_key" {
  description = "The Datadog API key."
  type        = string
  sensitive   = true
}

variable "datadog_site" {
  description = "The Datadog site to send logs to (e.g., datadoghq.com, datadoghq.eu)."
  type        = string
  default     = "datadoghq.com"
}
