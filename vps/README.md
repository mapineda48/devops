# VPS (pgAdmin + Monitoring) via Terraform

This project provisions a single DigitalOcean VPS and bootstraps it using cloud-init.
The VPS runs pgAdmin behind `nginx-proxy` + `acme-companion`, and includes a small
observability stack (Prometheus, Loki, node_exporter, cAdvisor).

It also includes a lightweight control plane based on Azure Service Bus to toggle
an ngrok tunnel on-demand.

## What it creates

- DigitalOcean droplet (Ubuntu)
- DigitalOcean firewall (22/80/443)
- Cloudflare A records (optional)
  - `${digitalocean_subdomain}.${cloudflare_zone_name}`
  - `pgadmin.${digitalocean_subdomain}.${cloudflare_zone_name}`

## Runtime components (cloud-init)

### Reverse proxy + TLS

- `nginxproxy/nginx-proxy` (container `mapineda48-proxy`)
- `nginxproxy/acme-companion` (container `mapineda48-acme`)
- Certificates and ACME state are persisted on Azure Blob via blobfuse2:
  - `/mnt/deploy/vm/agape.js/docker/certs`
  - `/mnt/deploy/vm/agape.js/docker/acme`

### pgAdmin

- Container: `dpage/pgadmin4:latest` (`mapineda48-pgadmin`)
- Exposed via the proxy using:
  - `VIRTUAL_HOST=${PGADMIN_VIRTUAL_HOST}`
  - `LETSENCRYPT_HOST=${PGADMIN_VIRTUAL_HOST}`
- pgAdmin data is stored on local disk to avoid SQLite-on-blobfuse pitfalls:
  - `/opt/mapineda48/data/pgadmin:/var/lib/pgadmin`

### Monitoring

- Prometheus (systemd service `mapineda48-prometheus.service`)
- Loki (systemd service `mapineda48-loki.service`)
- node_exporter (systemd service `mapineda48-node-exporter.service`)
- cAdvisor (systemd service `mapineda48-cadvisor.service`)
- Host nginx (port `8081`) proxies local Prometheus/Loki for convenience.

### Logs to Loki (clean debugging)

- journald is configured as persistent storage (`/var/log/journal`).
- promtail ships systemd journal logs to Loki, filtered to these units:
  - `mapineda48-servicebus-listener.service`
  - `mapineda48-ngrok.service`

## Azure Service Bus control plane (ngrok toggle)

Instead of a local UNIX socket service, this VPS listens to an Azure Service Bus queue.
When it receives a message it starts/stops ngrok.

- Listener code: `devops/vps/cloud-init/write_files/opt/mapineda48/servicebus/listener.py`
- Systemd unit: `devops/vps/cloud-init/write_files/etc/systemd/system/mapineda48-servicebus-listener.service`
- Ngrok systemd unit: `devops/vps/cloud-init/write_files/etc/systemd/system/mapineda48-ngrok.service`

### Supported events

- `pgadmin-toggle-ngrok`
- `pgadmin-ngrok-start`
- `pgadmin-ngrok-stop`

### Example payloads (Service Bus message body)

The listener accepts either plain text or JSON.

Plain text:

```text
pgadmin-toggle-ngrok
```

JSON:

```json
{
  "event": "pgadmin-toggle-ngrok"
}
```

## Configuration

cloud-init variables are rendered from `devops/vps/cloud-init/.env`.
Use `devops/vps/cloud-init/.env.example` as a template.

Required variables:

- `MAPINEDA48_EMAIL_ACME`
- `STORAGE_ACCOUNT_NAME`
- `STORAGE_ACCOUNT_KEY`
- `STORAGE_DEPLOY_CONTAINER`
- `PGADMIN_DEFAULT_EMAIL`
- `PGADMIN_DEFAULT_PASSWORD`
- `PGADMIN_VIRTUAL_HOST`
- `SERVICE_BUS_CONNECTION_STRING` (listener rights)
- `SERVICE_BUS_QUEUE_NAME` (e.g. `vps-control`)

Optional variables:

- `NGROK_AUTHTOKEN`
- `NGROK_DEV_DOMAIN`

## Usage

From `devops/vps/`:

```bash
terraform init -backend-config=backend.hcl
terraform apply
```

After apply, pgAdmin should respond on:

```bash
curl -I "https://${PGADMIN_VIRTUAL_HOST}/"
```

## Notes

- This repository reads `devops/core` remote state for Cloudflare zone outputs.
- Secrets in `cloud-init/.env` will be embedded into cloud-init user_data and may
  end up in Terraform state. Treat the backend as sensitive.
