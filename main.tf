###################################
# Locals: Cloud-init script for Nginx
###################################
locals {
  nginx_cloud_init = <<-CLOUDINIT
    #cloud-config
    packages:
      - docker.io
    runcmd:
      - systemctl start docker
      - usermod -aG docker ${var.admin_username}
      - docker run -d --restart=always -p 8080:80 nginx
  CLOUDINIT
}

###################################
# Networking (Resource Group, VNet, Subnet, NSG)
###################################

resource "azurerm_resource_group" "rg" {
  name     = "rg-devops-bootcamp-iac"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-devops-iac"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-devops-iac"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-devops-iac"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Allow inbound SSH
  security_rule {
    name                       = "SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }

  # Allow inbound HTTP on port 8080 (Nginx container)
  security_rule {
    name                       = "HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_attach" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

###################################
# Compute (Multiple VMs with for_each)
###################################

resource "azurerm_public_ip" "pip" {
  for_each            = var.vm_names
  name                = "pip-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  for_each            = var.vm_names
  name                = "nic-${each.key}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[each.key].id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each              = var.vm_names
  name                  = each.value
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic[each.key].id]

  # Cloud-init script for Docker + Nginx
  custom_data = base64encode(local.nginx_cloud_init)

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

###################################
# Outputs
###################################

output "vm_public_ips" {
  description = "Public IP addresses for the Dev, Test, and Prod VMs."
  value = {
    for key, pip in azurerm_public_ip.pip : key => pip.ip_address
  }
}