provider "azurerm" {
  version = "=1.28.0"
}
variable "prefix" {
  default = "d03"
}
resource "azurerm_resource_group" "main" {
  name = "${var.prefix}-resources"
  # az account list-locations --output table
  location = "Japan East"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
  address_space       = ["10.254.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "10.254.0.0/24"
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "network" {
  name                = "${var.prefix}-appgateway"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"

  backend_address_pool {
    name = "${var.prefix}-beap"
  }

  backend_http_settings {
    name                  = "${var.prefix}-be-htst"
    cookie_based_affinity = "Enabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = "30"
  }

  frontend_ip_configuration {
    name                          = "${var.prefix}-feip"
    public_ip_address_id          = "${azurerm_public_ip.main.id}"
    private_ip_address_allocation = "Dynamic"
  }

  frontend_port {
    name = "${var.prefix}-feport"
    port = 443
  }

  gateway_ip_configuration {
    name      = "${var.prefix}-gupconf"
    subnet_id = "${azurerm_subnet.frontend.id}"
  }

  http_listener {
    name                           = "${var.prefix}-httplstn"
    frontend_ip_configuration_name = "${var.prefix}-feip"
    frontend_port_name             = "${var.prefix}-feport"
    ssl_certificate_name           = "${var.prefix}-cert"
    protocol                       = "Https"
  }

  request_routing_rule {
    name                       = "${var.prefix}-rqrt"
    rule_type                  = "Basic"
    http_listener_name         = "${var.prefix}-httplstn"
    backend_address_pool_name  = "${var.prefix}-beap"
    backend_http_settings_name = "${var.prefix}-be-htst"
  }

  ssl_certificate {
    name = "${var.prefix}-cert"
    # https://www.terraform.io/docs/providers/azurerm/r/key_vault_certificate.html
    data     = "${filebase64("demo.pfx")}"
    password = "test"
  }

  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }

  autoscale_configuration {
    min_capacity = 2
    max_capacity = 10
  }
}
