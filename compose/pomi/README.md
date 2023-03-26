# Postgres - Minio - TLS - Development 

This repository contains a demo of how to use Docker Compose with several services. The services included are:

- nginx-proxy: A reverse proxy server that listens on ports 80 and 443 and forwards traffic to other services based on the domain name.
- nginx-proxy-acme: A companion service to nginx-proxy that automatically obtains SSL/TLS certificates from Let's Encrypt for the domains configured in nginx-proxy.
- minio: A self-hosted object storage server that listens on port 9000 and is used to store files and data.
- minio-gui: A web-based graphical user interface for minio, which is accessible at port 9090.
- db: A PostgreSQL database server that is used by the pgadmin service.
- pgadmin: A web-based administration tool for PostgreSQL databases, which is accessible at a domain configured in nginx-proxy.
app: A simple Nginx web server that serves static content and is accessible at a domain configured in nginx-proxy.

Volumes are created for storing certificates, virtual host configurations, website content, and acme.sh data.

## Let's Encrypt ACME Staging Server

The staging server is used for testing purposes and it uses test certificates that are not trusted by web browsers. This means that the certificates issued by the staging server are not suitable for use in a production environment, but are useful for testing and debugging.

## Usage

- Before getting started, you need to navigate to the minio-console directory and add the test root CAs to the trusted CA folder so that the Minio client can trust the certificates.

- After that, you can start the services with 'docker-compose up -d'.

- Optionally, you can add the CA to your system so that when viewing in the browser, it can trust the issued certificates, although it is not recommended for security reasons.

## Official Documentation

- https://letsencrypt.org/docs/rate-limits/
- https://letsencrypt.org/docs/staging-environment/