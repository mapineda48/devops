# Azure Kubernetes Services - Azure Container Register

This report documents a Terraform project that automates the creation of an AKS cluster and an ACR, and configures permissions to enable the cluster to download container images from the newly created registry. The project streamlines the deployment process by eliminating the need for manual setup and configuration, while ensuring consistency and reproducibility across multiple environments. This report provides an overview of the project's architecture and implementation, as well as a step-by-step guide for reproducing the deployment process.

## Usage

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

## K8s Manifiest Testings (Optional)

The combination of Ingress-Nginx, Cert-Manager, and External DNS in Kubernetes (k8s) is a popular solution for traffic management in Kubernetes and implementing TLS certificates in web applications on k8s.

Ingress-Nginx is an Ingress controller that implements the Ingress specification in Kubernetes using the Nginx web server. Ingress-Nginx allows for routing of HTTP and HTTPS traffic from outside the cluster to services inside the cluster. Additionally, it can perform load balancing and SSL/TLS termination on behalf of services.

Cert-Manager is a Kubernetes controller that is used to automatically issue and renew TLS certificates using certificate authority providers such as Let's Encrypt. Cert-Manager integrates well with Ingress-Nginx and can automatically request and issue certificates for properly configured Ingress services.

External DNS is another Kubernetes controller that is used to automatically configure DNS records for Kubernetes services in external DNS providers such as Amazon Route 53 or Google Cloud DNS. External DNS can automatically update DNS records for Ingress services, allowing services to be accessed via configured domain names.

The combination of Ingress-Nginx, Cert-Manager, and External DNS allows for easy and automated deployment of TLS certificates and traffic routing in Kubernetes. This allows developers to focus on implementing applications rather than configuring underlying infrastructure.

### Requirements

To test locally, you will need:

- A Debian-based Linux distribution.
- `kubectl` installed on your system.
- A registered domain with a DNS service provider such as GoDaddy.

### Usage

In order to apply the manifests, you'll need to create a terraform.tfvars file with the corresponding variables. Terraform will apply these configurations once the infrastructure is fully created. Please note that this step is optional and currently only works on Debian-based Linux distributions.

```tfvars
apply_k8s_manifiest=true

cluster_issuer_cert="foo@bar"

godaddy_api_key="my-api-key-godaddy"

godaddy_api_secret="my-api-secret-godaddy"

godaddy_domain="my-domain-godaddy"
```

## FAQs

- ¿How can I obtain the IP of the Ingress-nginx to configure the DNS?

One quick way is through the command line:

```sh
kubectl get service ingress-nginx-controller --namespace=ingress-nginx
```

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
- https://kubernetes.github.io/ingress-nginx/deploy/#azure
- https://learn.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli#create-an-ingress-controller
- https://cert-manager.io/docs/installation/kubectl/
- https://cert-manager.io/docs/configuration/acme/