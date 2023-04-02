# Azure Kubernetes Services - Azure Container Register

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
# Warning this will ereaser current config
echo "$(terraform output kube_config)" | sed '1d;$d' > ~/.kube/config
```

- Verify the health of the cluster
```sh
kubectl get nodes
```

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