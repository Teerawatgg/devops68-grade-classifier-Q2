resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  name = "${var.project_name}-${random_string.suffix.result}"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.name}"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${local.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-${local.name}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${local.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-app-port"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.app_port)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-${local.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "nic-${local.name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${local.name}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = var.vm_admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "osdisk-${local.name}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<-CLOUDINIT
#cloud-config
package_update: true
package_upgrade: false

packages:
  - git
  - curl
  - ca-certificates
  - gnupg
  - build-essential

write_files:
  - path: /usr/local/bin/deploy-grade-api.sh
    permissions: '0755'
    content: |
      #!/usr/bin/env bash
      set -euxo pipefail

      APP_DIR="${var.app_dir}"
      APP_PORT="${var.app_port}"
      REPO_URL="${var.repo_url}"
      REPO_BRANCH="${var.repo_branch}"
      APP_USER="${var.vm_admin_username}"

      export DEBIAN_FRONTEND=noninteractive

      curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
      apt-get update
      apt-get install -y nodejs

      systemctl stop grade-classifier.service || true
      rm -rf "$${APP_DIR}"
      install -d -o "$${APP_USER}" -g "$${APP_USER}" "$${APP_DIR}"

      su - "$${APP_USER}" -c "git clone --depth 1 -b '$${REPO_BRANCH}' '$${REPO_URL}' '$${APP_DIR}'"

      if [ -f "$${APP_DIR}/package-lock.json" ]; then
        su - "$${APP_USER}" -c "cd '$${APP_DIR}' && npm ci --omit=dev"
      else
        su - "$${APP_USER}" -c "cd '$${APP_DIR}' && npm install --omit=dev"
      fi

      cat > /etc/systemd/system/grade-classifier.service <<EOF
      [Unit]
      Description=Grade Classifier API
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=simple
      User=$${APP_USER}
      WorkingDirectory=$${APP_DIR}
      Environment=NODE_ENV=production
      Environment=PORT=$${APP_PORT}
      ExecStart=/usr/bin/node $${APP_DIR}/index.js
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target

      
        npm install
             
         # Run the app
        nohup npm run dev > app.log 2>&1 &
             
            echo "User Data Script Finished"
      EOF

      systemctl daemon-reload
      systemctl enable grade-classifier.service
      systemctl restart grade-classifier.service

      for i in $$(seq 1 20); do
        if curl -fsS "http://127.0.0.1:$${APP_PORT}/classify?score=85" >/dev/null; then
          exit 0
        fi
        sleep 3
      done

      systemctl status grade-classifier.service --no-pager || true
      journalctl -u grade-classifier.service --no-pager -n 100 || true
      exit 1

runcmd:
  - bash /usr/local/bin/deploy-grade-api.sh > /var/log/deploy-grade-api.log 2>&1
CLOUDINIT
  )

  depends_on = [
    azurerm_network_interface_security_group_association.nic_nsg
  ]

  tags = {
    environment = "quiz"
    project     = var.project_name
    owner       = var.vm_admin_username
  }
}