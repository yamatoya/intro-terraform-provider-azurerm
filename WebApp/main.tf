provider "azurerm" {
  version = "=1.28.0"
}
variable "prefix" {
  default = "d02"
}
resource "azurerm_resource_group" "main" {
  name = "${var.prefix}-resources"
  # az account list-locations --output table
  location = "Japan East"
}

resource "azurerm_app_service_plan" "test" {
  name                = "${var.prefix}-appserviceplan"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "test" {
  name                = "${var.prefix}-app-service"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  app_service_plan_id = "${azurerm_app_service_plan.test.id}"

  site_config {
    php_version = "7.2"
  }
}





