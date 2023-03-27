# resource "random_pet" "prefix" {}

# resource "random_pet" "acr" {
#   separator = ""
# }

variable "project_name" {
#  default = "${random_pet.prefix.id}"
  default = "foo"
}

variable "acr_name" {
#  default = "${random_pet.acr.id}"
  default = "fooacr"
}

variable "ssh_public_key" {
  default = "~/.ssh/id_rsa.pub"
}

variable "godaddy_api_key" {
  default = ""
}

variable "godaddy_api_secret" {
  default = ""
}

variable "godaddy_domain" {
  default = "mapineda48.xyz"
}