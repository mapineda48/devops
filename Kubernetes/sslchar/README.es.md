# Certificados SSL en Kubernetes

Este repositorio contiene un ejemplo muy basico de cómo implementar Certificados SSL en un clúster de Kubernetes utilizando Ingress-nginx, Cert Manager y Helm.


## Requisitos

- Disponer de un clúster de Kubernetes en un proveedor de infraestructura como Azure.
- Tener instalado `kubectl`.
- Tener instalado `helm`.
- Contar con un dominio registrado en un proveedor de servicios DNS como GoDaddy.

## Ingress-nginx

Ingress-nginx es un controlador de ingress para Kubernetes que nos permite enrutar el tráfico a los servicios desplegados en nuestro clúster. Es muy utilizado debido a su facilidad de configuración y flexibilidad. Para más información, puedes visitar el sitio oficial de Ingress-nginx en su [sitio web](https://kubernetes.github.io/ingress-nginx/).

## Cert Manager

Cert Manager es una herramienta para automatizar la emisión y renovación de certificados SSL/TLS en clústeres de Kubernetes. Para obtener más información sobre Cert Manager, visita su sitio oficial en su [sitio web](https://cert-manager.io/).

## Desplegar servicio de prueba

Después de añadir un registro A con el nombre de subdominio deseado y apuntar la dirección IP de tu clúster de Kubernetes, procede a instalar la demo siguiendo los siguientes pasos:

- Clona este repositorio:
```sh
git clone https://github.com/mapineda48/devops.git
```
- Accede al directorio del repositorio: 
```sh
cd <repo>/kubernetes/sslchar
```
- Instala la aplicación utilizando Helm:
```sh
helm install my-app . --set emailIssuerCert=<valor> --set host=<valor>
```

## Preguntas frecuentes

- ¿Obtener ip del ngnix ingress para configurar el DNS?

Una forma rapida es mediante la linea de comandos
```sh
kubectl get service ingress-nginx-controller --namespace=ingress-nginx
```

## Documentacion Oficial

- https://kubernetes.github.io/ingress-nginx/deploy/#azure
- https://learn.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli#create-an-ingress-controller
- https://cert-manager.io/docs/installation/kubectl/
- https://cert-manager.io/docs/configuration/acme/