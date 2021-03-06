provider "azurerm" {
  version = "=1.28.0"
}
variable "prefix" {
  default = "d01"
}
resource "azurerm_resource_group" "main" {
  name = "${var.prefix}-resources"
  # az account list-locations --output table
  location = "Japan East"
}

resource "azurerm_virtual_machine" "main" {
  name                = "${var.prefix}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  # https://docs.microsoft.com/ja-jp/azure/virtual-machines/windows/sizes?toc=%2Fazure%2Fvirtual-machines%2Fwindows%2Ftoc.json
  vm_size = "Standard_DS1_v2"

  os_profile {
    computer_name  = "${var.prefix}"
    admin_username = "ubuntu"
  }

  storage_os_disk {
    name              = "${var.prefix}-os-disk"
    create_option     = "FromImage"
    os_type           = "Linux"
    managed_disk_type = "Standard_LRS"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/ubuntu/.ssh/authorized_keys"
      key_data = "${file("C:\\git\\intro-terraform-provider-azurerm\\VirtualMachine\\Linux\\id_rsa.pub")}"
    }
  }

  network_interface_ids = ["${azurerm_network_interface.test-network.id}"]
}

resource "azurerm_virtual_network" "test" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.3.0/24"]
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}

resource "azurerm_subnet" "test" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.test.name}"
  address_prefix       = "10.0.3.0/24"
}
resource "azurerm_public_ip" "test" {
  name                = "${var.prefix}-publicip"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  allocation_method   = "Static"
}

resource "azurerm_network_security_group" "test" {
  name                = "${var.prefix}-nsg"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  security_rule {
    name                       = "${var.prefix}-nsg-ssh-rule"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "test-network" {
  name                = "${var.prefix}-ni"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"

  ip_configuration {
    name                          = "${var.prefix}-configuration"
    subnet_id                     = "${azurerm_subnet.test.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.test.id}"
  }
}
