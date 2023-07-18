terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">=3.65.0"
    }
  }
}

# 2. Configure the AzureRM Provider
provider "azurerm" {
  features {}
  subscription_id = "11e07d93-b7de-44c1-b006-7218b5fb3180"
  client_id       = "b30bfd9a-8e64-4c5a-ac79-c166d9ae713c"
  client_secret   = "mit8Q~qmWXTwifGCRrGggw0m97aJnXNLHwVdTaaZ"
  tenant_id       = "30bf9f37-d550-4878-9494-1041656caf27"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.rgname}"
  location = "${var.rglocation}"
}

locals {
  rg_info = azurerm_resource_group.rg.name
}
resource "azurerm_storage_account" "sa" {
  name                     = "${var.prefix}"
  resource_group_name      = "${local.rg_info}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
  blob_properties {
  cors_rule {
    allowed_origins     = ["*"]
    allowed_methods    = ["GET", "POST", "DELETE", "HEAD", "MERGE", "OPTIONS", "PUT", "PATCH"]
    allowed_headers    = ["*"]
    exposed_headers    = ["*"]
    max_age_in_seconds = 86400
}
}
}

resource "azurerm_mssql_server" "serverdemo" {
  name = "${var.prefix}"
  resource_group_name = "${local.rg_info}"
  location = "${azurerm_resource_group.rg.location}"
  version = "12.0"
  administrator_login = "snpadmin"
  administrator_login_password = "snp@1234"
}

resource "azurerm_mssql_database" "database" {
  name = "${var.prefix}-db"
  server_id = azurerm_mssql_server.serverdemo.id
  collation = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb = 250

}

resource "azurerm_app_service_plan" "demo" {
  name = "${var.prefix}-plan"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${local.rg_info}"
  kind = "Linux"
  reserved = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_linux_web_app" "app" {
  name = "${var.prefix}-front"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${local.rg_info}"
  service_plan_id = azurerm_app_service_plan.demo.id


  
  connection_string {
    name = "myconnection"
    type = "SQLServer"
    value = "Server=myserver;Database=mydatabase;User Id=myuser;Password=mypassword;"
  }
  site_config {
    always_on = true
  }
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.appi.instrumentation_key

  }

}

resource "azurerm_log_analytics_workspace" "work" {
  name = "${var.prefix}-workspace"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${local.rg_info}"
  sku = "PerGB2018"
  retention_in_days = 30

}

resource "azurerm_application_insights" "appi" {
  name = "${var.prefix}-appi"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${local.rg_info}"
  workspace_id = azurerm_log_analytics_workspace.work.id
  application_type = "web"

}




resource "azurerm_linux_web_app" "back" {
  name = "${var.prefix}-api-back"
  location = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${local.rg_info}"
  service_plan_id = azurerm_app_service_plan.demo.id


site_config {
  always_on = true

}

}




  
