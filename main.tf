terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.90.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

#Deployment Virtual Machine
#prefix
variable "prefix" {
  default = "linuxvm"
}

#resource_group
resource "azurerm_resource_group" "main" {
  name     = "linux"
  location = "norwayeast"
}

#networking
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.5.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

#subnet
resource "azurerm_subnet" "internal" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.5.1.0/24"]
}

#network_interface
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "${var.prefix}-ip"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ubuntu.id
  }
}

#pip
 resource "azurerm_public_ip" "ubuntu" {
   name                         = "${var.prefix}-pip"
   location                     = azurerm_resource_group.main.location
   resource_group_name          = azurerm_resource_group.main.name
   allocation_method = "Static"
 tags = {
     environment = "test"
   }
 }

#nsg
resource "azurerm_network_security_group" "ubuntu" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#vm
resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_B1s"

  # Delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

# List skus
# az vm image list-skus --location westus --publisher Canonical --offer UbuntuServer --output table

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "${var.prefix}-disk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "tux"
    admin_username = "changeme"
    admin_password = "changeme123!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "testing"
  }
}

output "ipaddres" {
      description = "The Public IP address is:"
      value = azurerm_public_ip.ubuntu.ip_address
       }