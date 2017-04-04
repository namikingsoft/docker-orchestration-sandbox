resource "null_resource" "tls_base" {
  provisioner "local-exec" {
    command = "./provisions/tlsgen-base.sh"
  }
}
