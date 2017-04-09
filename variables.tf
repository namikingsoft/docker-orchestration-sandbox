variable "ssh_public_key" {}
variable "ssh_private_key" {}
variable "ssh_fingerprint" {}
variable "do_token" {}
variable "gc_credentials" {}
variable "gc_project" {}
variable "gc_region" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_default_region" {}

provider "digitalocean" {
  token = "${var.do_token}"
}
