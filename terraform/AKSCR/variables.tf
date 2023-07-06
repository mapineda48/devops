variable "project_name" {
  default = "mapineda48"
}

variable "acr_name" {
  default = "mapineda48cr"
}

variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}

# Optional - Only if need user window image
variable "win_admin_username" {
  default = ""
}