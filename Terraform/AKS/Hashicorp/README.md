# Azure Kubernetes Services

## Before you start

- Create a file called `terraform.tfvars` and put in it you credentials services principal azure.
```tfvars
appId = "<service_principal_app_id>"
password = "<service_principal_password>"
```

## Create Cluster

- Initialize Terraform
```sh
terraform init
```

- Apply the execution plan to your cloud infrastructure
```sh
terraform apply
```
- Get the Kubernetes configuration from the Terraform state and store it in a file that kubectl can read
```sh
echo "$(terraform output kube_config)" > ~/.kube/config
```

- Verify the health of the cluster
```sh
kubectl get nodes
```
**Note:** if you have the follow error: `error loading config file "~\.kube\config": yaml: mapping values are not allowed in this context`, you should fix format of kube_config 

## Common questions

- Azure CLI Login
```sh
az login
```
- Destroy cluster
```sh
terraform destroy
```

# Official Documentation

- [Provision an AKS Cluster (Azure)](https://learn.hashicorp.com/tutorials/terraform/aks)