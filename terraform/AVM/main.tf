# https://learn.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-terraform
# https://www.phillipsj.net/posts/cloud-init-with-terraform/
# https://developer.hashicorp.com/terraform/language/resources/provisioners/remote-exec?utm_source=terraform-ls&utm_content=documentHover&utm_medium=Visual%20Studio%20Code
# https://developer.hashicorp.com/terraform/language/resources/provisioners/syntax

resource "random_pet" "project" {}

resource "azurerm_resource_group" "rg" {
  location = "eastus" # az account list-locations --query '[].name'
  name     = random_pet.project.id
}

# Create virtual network
resource "azurerm_virtual_network" "vm_network" {
  name                = "${random_pet.project.id}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "vm_subnet" {
  name                 = "${random_pet.project.id}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vm_network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "${random_pet.project.id}-public-iP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# My dynamic public IP
# I am going to create a rule in the virtual machine network security group
# to allow SSH connection only from my public IP.
data "external" "my_address" {
  program = ["bash", "-c", "curl ifconfig.me | jq -n --arg ip \"$(cat)\" '{\"ip\": $ip}'"]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${random_pet.project.id}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowSSHCreator"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = data.external.my_address.result.ip
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "vm_nic" {
  name                = "${random_pet.project.id}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "main_nic_configuration"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.vm_nic.id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "vm_vm" {
  name                  = "${random_pet.project.id}-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vm_nic.id]
  size                  = "Standard_D2s_v3" # az vm list-sizes --location eastus --query "[?starts_with(name, 'Standard_D2s')]"

  os_disk {
    name                 = "${random_pet.project.id}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS" # az vm image list --offer UbuntuServer --output table
    version   = "latest"
  }

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }


  connection {
    type        = "ssh"
    user        = self.admin_username
    host        = self.public_ip_address
    timeout     = "5m"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = "post-create.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /tmp/script.sh ${var.duckdns_token}"
    ]
    on_failure = continue
  }
}
