resource "digitalocean_ssh_key" "user" {
  name       = var.digitalocean_ssh_key_name
  public_key = file(var.digitalocean_ssh_public_key_path)
}

locals {
  digitalocean_fqdn = var.cloudflare_zone_name != null ? "${var.digitalocean_subdomain}.${var.cloudflare_zone_name}" : var.digitalocean_subdomain
}

resource "digitalocean_droplet" "main" {
  name     = var.digitalocean_droplet_name
  region   = var.digitalocean_region
  image    = var.digitalocean_image
  size     = var.digitalocean_droplet_size # $6/mo: 2 vCPU, 4GB RAM, 80GB SSD
  ssh_keys = [digitalocean_ssh_key.user.id]

  user_data = templatefile("${path.module}/cloud-init/digitalocean.yaml.tftpl", {
    fqdn              = local.digitalocean_fqdn
    letsencrypt_email = var.letsencrypt_email
  })
}

resource "digitalocean_firewall" "ssh_only" {
  name        = "${var.digitalocean_droplet_name}-ssh-only"
  droplet_ids = [digitalocean_droplet.main.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = [var.allowed_ssh_source_cidr]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "cloudflare_dns_record" "digitalocean_a" {
  count   = var.cloudflare_zone_name != null ? 1 : 0
  zone_id = cloudflare_zone.main[0].id
  name    = var.digitalocean_subdomain
  type    = "A"
  content = digitalocean_droplet.main.ipv4_address
  ttl     = 300
  proxied = false
  comment = "Managed by Terraform - DigitalOcean Droplet"
}
