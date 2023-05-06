variable "project_name" {
  default = "mapineda48"
}

variable "acr_name" {
  default = "mapineda48cr"
}

variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}


#################################### Optionals ############################################

variable "apply_k8s_manifiest"{
  default = false
}

variable "cluster_issuer_cert" {
  default = ""
  sensitive   = true
}

variable "godaddy_api_key" {
  default = ""
  sensitive   = true
}

variable "godaddy_api_secret" {
  default = ""
  sensitive   = true
}

variable "godaddy_domain" {
  default = ""
}