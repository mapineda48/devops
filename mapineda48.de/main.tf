provider "azurerm" {
  features {}
}

resource "random_string" "agape_secret" {
  length  = 64
  upper   = true
  lower   = true
  numeric = true
  special = false
}

resource "random_string" "agape_admin" {
  length  = 64
  upper   = true
  lower   = true
  numeric = true
  special = false
}

resource "random_string" "agape_password" {
  length  = 64
  upper   = true
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_resource_group" "agape_app" {
  name     = var.resource_group_name
  location = var.resource_group_location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-deploy"
  location            = var.resource_group_location
  resource_group_name = azurerm_resource_group.agape_app.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-deploy"
  resource_group_name = azurerm_resource_group.agape_app.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "public-ip"
  location            = azurerm_resource_group.agape_app.location
  resource_group_name = azurerm_resource_group.agape_app.name
  allocation_method   = "Static"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-deploy"
  location            = azurerm_resource_group.agape_app.location
  resource_group_name = azurerm_resource_group.agape_app.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-deploy"
  location            = azurerm_resource_group.agape_app.location
  resource_group_name = azurerm_resource_group.agape_app.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  dynamic "security_rule" {
    for_each = var.SOURCE_IP != "" && var.SOURCE_IP != null ? [1] : []

    content {
      name                       = "Allow-SSH-From-MyIP"
      priority                   = 120
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = var.SOURCE_IP
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = var.dns_subdomain
  location            = azurerm_resource_group.agape_app.location
  resource_group_name = azurerm_resource_group.agape_app.name
  size                = "Standard_B2s"
  admin_username      = "azureuser"

  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "osdisk-vm"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

custom_data = base64encode(templatefile("${path.module}/cloud-init.tpl.yaml", {

  dockerhub_webhook_fqdn    = "${var.dns_subdomain_dockerhub_webhook}.${var.dns_zone_name}"
  agape_app_fqdn            = "${var.dns_subdomain}.${var.dns_zone_name}"
  agape_secret              = random_string.agape_secret.result
  agape_admin               = random_string.agape_admin.result
  agape_password            = random_string.agape_password.result

  storage_account_name      = var.STORAGE_ACCOUNTNAME
  storage_account_key       = var.STORAGE_ACCOUNTKEY
  default_email_acme        = var.DEFAULT_EMAIL_ACME
  dockerhub_webhook_secret  = var.DOCKERHUB_WEBHOOK_SECRET
  database_uri              = var.DATABASE_URI
  azure_connection_string   = var.STORAGE_CONNECTION_STRING
  agape_tenant              = var.AGAPE_TENANT
}))

  disable_password_authentication = true
}

resource "azurerm_dns_a_record" "vm_subdomain" {
  name                = var.dns_subdomain
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name_mapineda48
  ttl                 = 300
  records             = [azurerm_public_ip.public_ip.ip_address]
}

resource "azurerm_dns_a_record" "dockerhub_webhook_subdomain" {
  name                = var.dns_subdomain_dockerhub_webhook
  zone_name           = var.dns_zone_name
  resource_group_name = var.resource_group_name_mapineda48
  ttl                 = 300
  records             = [azurerm_public_ip.public_ip.ip_address]
}