# Azure Storage Account - Terraform

Este repositorio contiene la infraestructura como código (IaC) para desplegar recursos en Azure utilizando Terraform.

## 📁 Estructura del Proyecto

```
.
├── main.tf                    # Recursos principales
├── variables.tf               # Definición de variables
├── outputs.tf                 # Outputs del módulo
├── providers.tf               # Configuración de providers
├── versions.tf                # Versiones requeridas
├── terraform.tfvars.example   # Ejemplo de valores de variables
├── .gitignore                 # Archivos ignorados por Git
└── README.md                  # Esta documentación
```

## 🚀 Recursos Creados

- **Resource Group**: Grupo de recursos de Azure
- **Storage Account**: Cuenta de almacenamiento con nombre aleatorio
- **Blob Container**: Contenedor para almacenar blobs

## 📋 Prerrequisitos

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) instalado y configurado
- Una suscripción de Azure activa

## 🔧 Configuración

1. **Autenticarse en Azure**:

   ```bash
   az login
   az account set --subscription "<SUBSCRIPTION_ID>"
   ```

2. **Copiar el archivo de variables de ejemplo**:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

3. **Editar `terraform.tfvars`** con los valores deseados.

## 🛠️ Uso

### Inicializar Terraform

```bash
terraform init
```

### Ver el plan de ejecución

```bash
terraform plan
```

### Aplicar los cambios

```bash
terraform apply
```

### Destruir la infraestructura

```bash
terraform destroy
```

## 📤 Outputs

| Nombre                                  | Descripción                                          |
| --------------------------------------- | ---------------------------------------------------- |
| `resource_group_name`                   | Nombre del resource group                            |
| `resource_group_id`                     | ID del resource group                                |
| `storage_account_name`                  | Nombre del storage account (generado aleatoriamente) |
| `storage_account_id`                    | ID del storage account                               |
| `storage_account_primary_blob_endpoint` | Endpoint del blob storage                            |
| `storage_account_primary_access_key`    | Access key del storage (sensitive)                   |
| `container_name`                        | Nombre del blob container                            |

## 🔒 Seguridad

El Storage Account está configurado con las siguientes mejores prácticas:

- **TLS 1.2** como versión mínima
- **Acceso público a blobs deshabilitado**
- **Versionado de blobs habilitado**
- **Política de retención** para eliminación de blobs y containers (7 días)

## 📝 Notas

- El nombre del Storage Account se genera automáticamente usando el provider `random` para garantizar unicidad (los nombres deben ser únicos globalmente en Azure).
- El archivo `terraform.tfvars` está excluido del repositorio por contener potencialmente información sensible.
- Se recomienda usar un backend remoto (como Azure Blob Storage) para almacenar el estado de Terraform en entornos de equipo.

## 📄 Licencia

MIT
