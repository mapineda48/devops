# Azure Infrastructure as Code with Terraform

This project defines the infrastructure for Azure using Terraform, featuring secure storage resources with modern best practices.

---

## 📦 Remote Backend with Azure Blob Storage

This project uses a remote backend to store Terraform state in an Azure Blob Storage container, enabling team collaboration and state locking.

> ⚠️ **Important:** Sensitive backend values (resource group, storage account, container, etc.) **must NOT be committed to `.tf` files**. Instead, configure them using an external `backend.hcl` file, which is excluded from Git.

---

## 🚀 Getting Started

### 1. Create your `backend.hcl` file

Create a file named `backend.hcl` in the project root (do not commit to repository):

```hcl
resource_group_name  = "my-terraform-rg"
storage_account_name = "mytfstatestore"
container_name       = "tfstate"
key                  = "core.tfstate"
```

### 2. Initialize Terraform

Run the following command to initialize Terraform with the remote backend:

```bash
terraform init -backend-config=backend.hcl
```

This command is only required when:

- Using the project for the first time
- The `backend.hcl` file has changed
- Backend or provider configuration has been modified

---

## 📁 Project Structure

```
.
├── main.tf                    # Main infrastructure resources
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── providers.tf               # Provider configuration
├── versions.tf                # Version constraints and backend config
├── backend.hcl.example        # Backend configuration template
├── terraform.tfvars.example   # Example variable values
├── .gitignore                 # Files excluded from Git
└── README.md                  # This documentation
```

---

## 🏗️ Resources Created

This Terraform configuration provisions the following Azure resources:

- **Resource Group**: Logical container for Azure resources
- **Storage Account**: Blob storage with randomly generated unique name
- **Blob Container**: Private container with randomly generated name for data storage

All resources are configured following Azure security best practices.

---

## 📋 Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.9.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and configured
- Active Azure subscription
- Appropriate permissions to create resources in Azure
- DigitalOcean API token exported as `DIGITALOCEAN_TOKEN`
- Existing DNS zone `mapineda48.de` in Cloudflare

For DigitalOcean SSH access, create a dedicated key pair (if it does not exist yet):

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_digitalocean -C "mapineda48@digitalocean" -N ""
```

---

## 🔧 Configuration

### 1. Authenticate to Azure

```bash
az login
az account set --subscription "<SUBSCRIPTION_ID>"
```

### 2. Copy the example variables file

```bash
cp terraform.tfvars.example terraform.tfvars
```

### 3. Edit `terraform.tfvars`

Update the file with your desired values:

```hcl
location              = "East US"
resource_group_name   = "rg-myproject-core"
storage_account_tier  = "Standard"
storage_account_replication_type = "LRS"

tags = {
  Environment = "Production"
  ManagedBy   = "Terraform"
  Project     = "MyProject"
}
```

---

## 🛠️ Usage

### Initialize Terraform

Initialize the working directory and download required providers:

```bash
terraform init -backend-config=backend.hcl
```

### Preview changes

Review the execution plan before applying:

```bash
terraform plan
```

### Apply configuration

Create or update infrastructure:

```bash
terraform apply
```

### Destroy infrastructure

Remove all managed infrastructure:

```bash
terraform destroy
```

---

## 📤 Outputs

| Output Name                              | Description                                    |
| ---------------------------------------- | ---------------------------------------------- |
| `resource_group_name`                    | Name of the resource group                     |
| `resource_group_id`                      | Resource ID of the resource group              |
| `storage_account_name`                   | Name of the storage account (randomly generated) |
| `storage_account_id`                     | Resource ID of the storage account             |
| `storage_account_primary_blob_endpoint`  | Primary blob endpoint URL                      |
| `storage_account_primary_access_key`     | Primary access key (sensitive)                 |
| `container_name`                         | Name of the blob container                     |

To view outputs after applying:

```bash
terraform output
```

---

## 🔒 Security Features

The Storage Account is configured with the following security best practices:

- **TLS 1.2** minimum version (Azure will require TLS 1.2+ by August 2025)
- **Public blob access disabled** at the account level
- **Blob versioning enabled** for data protection
- **Change feed enabled** for audit and compliance
- **Last access time tracking** for lifecycle management
- **Soft delete retention** for blobs and containers (7 days)
- **Randomly generated names** to ensure global uniqueness

---

## 📝 Important Notes

- **Unique Naming**: Storage account and container names are generated automatically using the `random` provider to guarantee global uniqueness (required by Azure)
- **State Management**: The `terraform.tfvars` and `backend.hcl` files are excluded from the repository as they may contain sensitive information
- **Team Collaboration**: Using a remote backend (Azure Blob Storage) is strongly recommended for team environments to enable state locking and consistency
- **Version Pinning**: Provider versions are constrained but allow minor/patch updates (`~> 4.0` for azurerm, `~> 3.0` for random)

---

## 🔄 Backend Configuration

The remote backend prevents state conflicts when working in teams. Each time you run Terraform, it:

1. Locks the state file to prevent concurrent modifications
2. Retrieves the latest state from Azure Blob Storage
3. Applies changes and updates the remote state
4. Releases the lock

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly with `terraform plan`
5. Submit a pull request

---

## 📄 License

MIT

---

## 📚 Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Blob Storage Documentation](https://docs.microsoft.com/en-us/azure/storage/blobs/)
- [Terraform Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
