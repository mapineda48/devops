# Azure Kubernetes Services

## Before you start

- Make sure you have a public key to establish the ssh connection.

- Create a file called `terraform.tfvars` and put in it you credentials services principal azure.
```tfvars
aks_service_principal_app_id = "<service_principal_app_id>"
aks_service_principal_client_secret = "<service_principal_password>"
```
## Create Cluster

- Initialize Terraform
```sh
terraform init
```

- Create a Terraform execution plan
```sh
terraform plan -out main.tfplan
```

- Apply the execution plan to your cloud infrastructure
```sh
terraform apply main.tfplan
```
- Get the Kubernetes configuration from the Terraform state and store it in a file that kubectl can read
```sh
echo "$(terraform output kube_config)" > ~/.kube/config
```

- Verify the health of the cluster
```sh
kubectl get nodes
```

- [Verify the results](https://learn.microsoft.com/en-us/azure/developer/terraform/create-k8s-cluster-with-tf-and-aks#verify-the-results)

## Common questions

- Azure CLI Login
```sh
az login
```
- Destroy cluster
```sh
terraform plan -destroy -out main.destroy.tfplan
terraform apply main.destroy.tfplan
```


# Official Documentation

- [Create and manage SSH keys for authentication to a Linux VM in Azure](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/create-ssh-keys-detailed)
- [Create an Azure service principal with the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli)
- [How to manage service principals - Azure Portal](https://docs.microsoft.com/en-us/azure/developer/python/how-to-manage-service-principals)
- [Install the Azure Az PowerShell module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-8.3.0)
- [Active Directory - Az PowerShell](https://docs.microsoft.com/en-us/powershell/module/az.resources/?view=azps-8.3.0#active-directory)
- [Terraform Download](https://www.terraform.io/downloads)
- [Update PATH variable](https://zwbetz.com/how-to-add-a-binary-to-your-path-on-macos-linux-windows/#:~:text=Windows%20GUI%20%23%201%20Create%20folder%20C%3A%5Cbin%202,settings%205%20Click%20Environment%20Variables%20More%20items...%20)
- [Create K8s cluster with terraform and AKS](https://docs.microsoft.com/en-us/azure/developer/terraform/create-k8s-cluster-with-tf-and-aks)