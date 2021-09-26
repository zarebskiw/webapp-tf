terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.76.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "ws-devops"
    storage_account_name = "cgmsgtf"
    container_name       = "tfstateazdevops"
    key                  = "<your unique prefix>.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Get resource group
data "azurerm_resource_group" "wsdevops" {
  name = "ws-devops"
}

################################################
# create infra
################################################

resource "azurerm_app_service_plan" "sp1" {
  name                = "sp<your unique prefix>"
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
  name                = "as<your unique prefix>"
  location            = data.azurerm_resource_group.wsdevops.location
  resource_group_name = data.azurerm_resource_group.wsdevops.name
  app_service_plan_id = azurerm_app_service_plan.sp1.id

  site_config {
    linux_fx_version = "NODE|10-lts"
    scm_type         = "LocalGit"
  }
}

resource "azurerm_log_analytics_workspace" "log" {
  name                = "log<your unique prefix>"
  location            = data.azurerm_resource_group.wsdevops.location
  resource_group_name = data.azurerm_resource_group.wsdevops.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "appi" {
  name                = "appi<your unique prefix>"
  location            = data.azurerm_resource_group.wsdevops.location
  resource_group_name = data.azurerm_resource_group.wsdevops.name
  workspace_id        = azurerm_log_analytics_workspace.log.id
  application_type    = "web"
}

resource "null_resource" "link_monitoring" {
  provisioner "local-exec" {
    command = <<EOT
      # Login to Azure CLI (Linux operating system assumed)
      az login --service-principal -u $con_client_id -p $con_client_secret --tenant $con_tenant_id
      # Change app settings
      az webapp config appsettings set --name $web_app_name --resource-group $rg_name --settings APPINSIGHTS_INSTRUMENTATIONKEY=$inst_key APPLICATIONINSIGHTS_CONNECTION_STRING=$inst_key ApplicationInsightsAgent_EXTENSION_VERSION=~2
    EOT
    environment = {
      // Parameters needed to login
      con_client_id     = var.client_id
      con_client_secret = var.client_secret
      con_tenant_id     = var.tenant_id
      // Parameters needed for linking
      inst_key          = azurerm_application_insights.appi.instrumentation_key
      rg_name           = data.azurerm_resource_group.wsdevops.name
      web_app_name      = var.web_app_name
    }
  }
}

data "template_file" "dash-template" {
  template = "${file("${path.module}/dashboard.tpl")}"
  vars = {
    api_name = azurerm_application_insights.appi.name
    rg_name  = data.azurerm_resource_group.wsdevops.name
    sub_id   = var.subscription_id
    query    = "requests | where resultCode != 200 | summarize count()"
  }
}

resource "azurerm_dashboard" "my-board" {
  name                = "db<your unique prefix>"
  resource_group_name = data.azurerm_resource_group.wsdevops.name
  location            = data.azurerm_resource_group.wsdevops.location
  tags = {
    source = "terraform"
  }
  dashboard_properties = data.template_file.dash-template.rendered
}

