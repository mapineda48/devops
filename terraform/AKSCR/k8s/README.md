# Personal Manifiest Testings

This repository contains a very basic example of how to implement SSL certificates on a Kubernetes cluster using Ingress-nginx, Cert Manager, and Helm.

## Requirements

To test locally, you will need:

- A Kubernetes cluster on an infrastructure provider such as Azure.
- `kubectl` installed.
- `helm` installed.
- A domain registered with a DNS service provider such as GoDaddy.

## Ingress-nginx

Ingress-nginx is an ingress controller for Kubernetes that allows us to route traffic to the services deployed in our cluster. It is widely used due to its ease of configuration and flexibility. For more information, visit the [official Ingress-nginx website](https://kubernetes.github.io/ingress-nginx/).

## Cert Manager

Cert Manager is a tool for automating the issuance and renewal of SSL/TLS certificates on Kubernetes clusters. For more information on Cert Manager, visit [their official website](https://cert-manager.io/).

## Deploying test service

Create a `.env` file in this folder with follow variables:

```sh
CLUSTER_ISSUER_EMAIL="foo@bar.com"

GODADDY_API_KEY="my-api-key"

GODADDY_API_SECRET="my-api-secret"

GODADDY_DOMAIN="foo.com"
```

Now run
```sh
bash ./apply.sh
```

## FAQs

- ¿How can I obtain the IP of the Ingress-nginx to configure the DNS?

One quick way is through the command line:

```sh
kubectl get service ingress-nginx-controller --namespace=ingress-nginx
```

## Official Documentation

- https://kubernetes.github.io/ingress-nginx/deploy/#azure
- https://learn.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli#create-an-ingress-controller
- https://cert-manager.io/docs/installation/kubectl/
- https://cert-manager.io/docs/configuration/acme/