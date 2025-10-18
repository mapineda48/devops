# Infraestructura Terraform - Azure

Este proyecto define la infraestructura para el entorno `mapineda48.de` en Azure utilizando Terraform.

---

## 📦 Backend remoto en Azure Blob Storage

Este proyecto utiliza un backend remoto para almacenar el estado de Terraform en un contenedor de Azure Blob Storage.

> ⚠️ **Importante:** Los valores sensibles del backend (grupo de recursos, cuenta de almacenamiento, contenedor, etc.) **NO deben estar en los archivos `.tf`**. En su lugar, se configuran mediante un archivo externo `backend.hcl`, el cual debe ser ignorado por Git.

---

## 🚀 Pasos de uso

### 1. Crear tu archivo `backend.hcl`

Crea un archivo llamado `backend.hcl` en la raíz del proyecto (no se debe subir al repositorio). Ejemplo:

```hcl
resource_group_name  = "agape_app-rg"
storage_account_name = "dedvx6qpk12345"
container_name       = "tfstate"
key                  = "deploy.tfstate"
````

### 2. Inicializar Terraform

Ejecuta el siguiente comando para inicializar Terraform con el backend remoto:

```bash
terraform init -backend-config=backend.hcl
```

Este comando solo es necesario:

* La primera vez que usas el proyecto
* Si cambia el archivo `backend.hcl`
* Si cambias el backend o proveedor

### 3. Aplicar cambios

Una vez inicializado, puedes ejecutar Terraform normalmente:

```bash
terraform plan
terraform apply
```

No es necesario volver a ejecutar `terraform init` a menos que se modifique el backend.

---

## 🔐 Seguridad

* Asegúrate de agregar `backend.hcl` al archivo `.gitignore` para evitar subir datos sensibles al repositorio.
* Puedes usar un archivo de ejemplo llamado `backend.example.hcl` para compartir la estructura con tu equipo.

### `.gitignore` recomendado:

```gitignore
# Terraform
*.tfstate
*.tfstate.*
.terraform/
terraform.tfvars
crash.log

# Backend config (local y sensible)
backend.hcl
```

---

## 🧠 Buenas prácticas

* Nunca incluyas datos sensibles (claves, nombres de storage, etc.) en archivos `.tf`.
* Usa entornos separados (`dev`, `prod`) con diferentes archivos `backend-*.hcl` y ejecútalos con:

```bash
terraform init -backend-config=backend-dev.hcl
```

---

## 📁 Estructura esperada

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.example.hcl
├── .gitignore
└── README.md
```

---

## 📎 Referencias

* [Terraform AzureRM Backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
