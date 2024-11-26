# Required Providers
provider "aws" {
  alias  = "aws"
  region = "us-east-1"
}

provider "azurerm" {
  alias           = "azure"
  region = "eastus"
  features        = {}
}

# --- AWS Configuration ---

# AWS VPC
resource "aws_vpc" "main" {
  provider   = aws
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "aws_vpc"
  }
}

# AWS Subnet
resource "aws_subnet" "subnet" {
  provider                = aws
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "aws_subnet"
  }
}

# AWS Security Group
resource "aws_security_group" "aws_sg" {
  provider = aws
  vpc_id   = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws_sg"
  }
}

# AWS EC2 Instance
resource "aws_instance" "aws_ec2" {
  provider      = aws
  ami           = "ami-0c55b159cbfafe1f0"  # Ubuntu AMI in us-east-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.subnet.id
  security_groups = [aws_security_group.aws_sg.name]

  tags = {
    Name = "aws_ec2_instance"
  }
}

# --- Azure Configuration ---

# Azure Resource Group
resource "azurerm_resource_group" "rg" {
  provider = azurerm.azure
  name     = "azureResourceGroup"
  location = "East US"

  tags = {
    environment = "test"
  }
}

# Azure Virtual Network
resource "azurerm_virtual_network" "vnet" {
  provider            = azurerm.azure
  name                = "azureVNet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]

  tags = {
    Name = "azure_vnet"
  }
}

# Azure Subnet
resource "azurerm_subnet" "subnet" {
  provider                 = azurerm.azure
  name                     = "azureSubnet"
  resource_group_name      = azurerm_resource_group.rg.name
  virtual_network_name     = azurerm_virtual_network.vnet.name
  address_prefixes         = ["10.1.1.0/24"]
}

# Azure Network Interface
resource "azurerm_network_interface" "nic" {
  provider            = azurerm.azure
  name                = "azureNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "azureNICConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    Name = "azure_nic"
  }
}

# Azure Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  provider            = azurerm.azure
  name                = "azureVM"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")  # Path to your public SSH key
  }

  tags = {
    Name = "azure_vm"
  }
}
