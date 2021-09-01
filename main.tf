provider "azurerm" {
  features {}
}

#Resource Groups
resource "azurerm_resource_group" "rg" {
  name     = "UbuntuLinux"
  location = "norwayeast"
}

#Networking
resource "azurerm_virtual_network" "ubuntu" {
  name                = "vNet01"
  address_space       = ["17.2.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "ubuntu" {
  name                 = "subnet01"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = "vNet01"
  address_prefixes     = ["17.2.1.0/24"]
  depends_on = [
    azurerm_virtual_network.ubuntu
  ]
  
}

#VM NIC
resource "azurerm_network_interface" "ubuntu" {
  name                = "ubuntulinux-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internalIP"
    subnet_id                     = azurerm_subnet.ubuntu.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ubuntu.id
  }
}

resource "azurerm_linux_virtual_machine" "ubuntu" {
  name                = "ubuntuLinuxVM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "admin"
  admin_password      = "admin1234"
  network_interface_ids = [
    azurerm_network_interface.ubuntu.id,
  ]

  admin_ssh_key {
    username   = "admin"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_public_ip" "ubuntu" {
  name                = "ubuntu01publicip1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "ubuntu" {
  name                = "ubuntu-security-group1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

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

resource "azurerm_network_interface_security_group_association" "ubuntu" {
    network_interface_id      = azurerm_network_interface.ubuntu.id
    network_security_group_id = azurerm_network_security_group.ubuntu.id
}
