variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-mapineda48-core"
}

variable "storage_account_tier" {
  description = "Tier of the storage account"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Replication type for the storage account"
  type        = string
  default     = "LRS"
}

variable "dns_zone_name" {
  description = "Name of the DNS zone"
  type        = string
  default     = "mapineda48.de"
}

variable "dns_www_target" {
  description = "Target CNAME for www subdomain (e.g., username.github.io)"
  type        = string
  default     = "mapineda48.github.io"
}

# Cloudflare variables
variable "cloudflare_account_id" {
  description = "Cloudflare Account ID (find it in Cloudflare dashboard)"
  type        = string
  default     = null
  sensitive   = true
}

variable "cloudflare_zone_name" {
  description = "Domain name to manage in Cloudflare (e.g., example.com)"
  type        = string
  default     = null
}

# Cloudflare Worker settings
variable "worker_sas_ttl_seconds" {
  description = "SAS token TTL in seconds (how long the token is valid)"
  type        = number
  default     = 120
}

variable "worker_edge_ttl_seconds" {
  description = "Edge cache TTL in seconds (how long Cloudflare caches the blob)"
  type        = number
  default     = 86400
}

variable "worker_browser_ttl_seconds" {
  description = "Browser cache TTL in seconds (Cache-Control max-age)"
  type        = number
  default     = 3600
}

variable "worker_forbidden_html_file" {
  description = "Path to the custom 403 HTML file used by the Cloudflare Worker"
  type        = string
  default     = "www/forbidden.html"
}

variable "worker_bad_request_html_file" {
  description = "Path to the custom 400 HTML file used by the Cloudflare Worker"
  type        = string
  default     = "www/bad-request.html"
}

variable "worker_missing_config_html_file" {
  description = "Path to the custom missing-config HTML file used by the Cloudflare Worker"
  type        = string
  default     = "www/missing-config.html"
}

variable "worker_origin_fallback_html_file" {
  description = "Path to the custom origin fallback HTML file used by the Cloudflare Worker"
  type        = string
  default     = "www/origin-fallback.html"
}

variable "worker_internal_error_html_file" {
  description = "Path to the custom internal error HTML file used by the Cloudflare Worker"
  type        = string
  default     = "www/internal-error.html"
}

# DigitalOcean variables
variable "digitalocean_region" {
  description = "DigitalOcean region for Droplet resources"
  type        = string
  default     = "fra1"
}

variable "digitalocean_image" {
  description = "DigitalOcean image slug for the Droplet"
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "digitalocean_droplet_name" {
  description = "Droplet name"
  type        = string
  default     = "digitalocean-mapineda48"
}

variable "digitalocean_droplet_size" {
  description = "Droplet size slug"
  type        = string
  default     = "s-2vcpu-4gb"
}

variable "digitalocean_subdomain" {
  description = "Subdomain for the Droplet A record"
  type        = string
  default     = "digitalocean"
}

variable "letsencrypt_email" {
  description = "Email used by acme-companion to request Let's Encrypt certificates"
  type        = string
  default     = "a.pinedavegamiguel@gmail.com"
}

variable "digitalocean_ssh_key_name" {
  description = "Name used in DigitalOcean for the uploaded SSH key"
  type        = string
  default     = "mapineda48-do"
}

variable "digitalocean_ssh_public_key_path" {
  description = "Path to the SSH public key file that will be uploaded to DigitalOcean"
  type        = string
  default     = "~/.ssh/id_ed25519_digitalocean.pub"
}

variable "allowed_ssh_source_cidr" {
  description = "CIDR allowed to connect via SSH (your public IP in /32 format)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
  }
}
