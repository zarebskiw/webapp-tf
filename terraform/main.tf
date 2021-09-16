terraform {
  backend "azurerm" {
    resource_group_name  = "ws-devops"
    storage_account_name = "cgmsgtf"
    container_name       = "tfstateazdevops"
    key                  = "flolie4123.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# data "azurerm_client_config" "current" {}


#Get resource group
data "azurerm_resource_group" "wsdevops" {
  name = "ws-devops"
}

#create infra

resource "azurerm_app_service_plan" "sp1" {
  name                = "spflolie4123"
  location            = data.azurerm_resource_group.wsdevops.location
  resource_group_name = data.azurerm_resource_group.wsdevops.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "website" {
  name                = "asflolie4123"
  location            = data.azurerm_resource_group.wsdevops.location
  resource_group_name = data.azurerm_resource_group.wsdevops.name
  app_service_plan_id = azurerm_app_service_plan.sp1.id

  site_config {
    linux_fx_version = "NODE|10-lts"
    scm_type         = "LocalGit"
  }
}


