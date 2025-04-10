terraform {
  required_version = ">= 0.13"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.35.0, < 4.1.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Generate a random ID for resource names
resource "random_string" "id" {
  length  = 5
  upper   = false
  special = false
}

# Common tags for resources
locals {
  common_tags = {
    Environment = "Production"
    Service     = "Datadog Log Forwarder"
    ManagedBy   = "Terraform"
  }
}

# Resource group for all resources
resource "azurerm_resource_group" "resource_group" {
  name     = format("rg-dd-log-forwarder-%s", random_string.id.result)
  location = var.location
  tags     = local.common_tags
}
