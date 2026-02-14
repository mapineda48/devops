# -----------------------------------------------------------------------------
# Cloudflare Worker - SAS Gateway for Azure Blob Storage
# This worker proxies requests to Azure Blob Storage with SAS tokens
# generated server-side, keeping blobs private while serving via CDN
# -----------------------------------------------------------------------------

# Worker Script
resource "cloudflare_workers_script" "sas_gateway" {
  count       = var.cloudflare_zone_name != null ? 1 : 0
  account_id  = var.cloudflare_account_id
  script_name = "sas-gateway"

  content = file("${path.module}/worker.js")

  # Environment variable bindings (secrets)
  bindings = [
    {
      name = "AZ_STORAGE_ACCOUNT"
      text = azurerm_storage_account.main.name
      type = "plain_text"
    },
    {
      name = "AZ_STORAGE_ACCOUNT_KEY"
      text = azurerm_storage_account.main.primary_access_key
      type = "secret_text"
    },
    {
      name = "AZ_SAS_TTL_SECONDS"
      text = tostring(var.worker_sas_ttl_seconds)
      type = "plain_text"
    },
    {
      name = "AZ_EDGE_TTL_SECONDS"
      text = tostring(var.worker_edge_ttl_seconds)
      type = "plain_text"
    },
    {
      name = "AZ_BROWSER_TTL_SECONDS"
      text = tostring(var.worker_browser_ttl_seconds)
      type = "plain_text"
    },
    {
      name = "AZ_BAD_REQUEST_HTML"
      text = file("${path.module}/${var.worker_bad_request_html_file}")
      type = "plain_text"
    },
    {
      name = "AZ_FORBIDDEN_HTML"
      text = file("${path.module}/${var.worker_forbidden_html_file}")
      type = "plain_text"
    },
    {
      name = "AZ_MISSING_CONFIG_HTML"
      text = file("${path.module}/${var.worker_missing_config_html_file}")
      type = "plain_text"
    },
    {
      name = "AZ_ORIGIN_FALLBACK_HTML"
      text = file("${path.module}/${var.worker_origin_fallback_html_file}")
      type = "plain_text"
    },
    {
      name = "AZ_INTERNAL_ERROR_HTML"
      text = file("${path.module}/${var.worker_internal_error_html_file}")
      type = "plain_text"
    }
  ]

  # Use ES modules format
  main_module = "worker.js"

  # Compatibility settings
  compatibility_date  = "2024-01-01"
  compatibility_flags = ["nodejs_compat"]
}

# Worker Route - Route cdn.domain.com/* to the worker
resource "cloudflare_workers_route" "sas_gateway" {
  count   = var.cloudflare_zone_name != null ? 1 : 0
  zone_id = cloudflare_zone.main[0].id
  pattern = "cdn.${var.cloudflare_zone_name}/*"
  script  = cloudflare_workers_script.sas_gateway[0].script_name
}

# -----------------------------------------------------------------------------
# Cache Rule - Ensure CDN caching with query string ignored
# This is a fallback/additional layer to ensure caching works correctly
# Note: The Worker itself handles caching via Cloudflare Cache API, but this
# rule provides an additional layer of cache configuration at the edge.
# -----------------------------------------------------------------------------
resource "cloudflare_ruleset" "cdn_cache_rules" {
  count       = var.cloudflare_zone_name != null ? 1 : 0
  zone_id     = cloudflare_zone.main[0].id
  name        = "CDN Cache Rules"
  description = "Cache rules for CDN subdomain"
  kind        = "zone"
  phase       = "http_request_cache_settings"

  rules = [
    {
      action      = "set_cache_settings"
      expression  = "(http.host eq \"cdn.${var.cloudflare_zone_name}\")"
      description = "Cache everything on CDN subdomain"
      enabled     = true
      action_parameters = {
        cache = true
        edge_ttl = {
          mode    = "override_origin"
          default = var.worker_edge_ttl_seconds
        }
        browser_ttl = {
          mode    = "override_origin"
          default = var.worker_browser_ttl_seconds
        }
      }
    }
  ]
}
