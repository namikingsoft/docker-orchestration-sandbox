variable "do_token" {}
variable "pub_key" {}
variable "pvt_key" {}
variable "ssh_fingerprint" {}

provider "digitalocean" {
  token = "${var.do_token}"
}

resource "digitalocean_droplet" "leader" {
  image = "ubuntu-16-04-x64"
  name = "swarm-leader"
  region = "sgp1"
  size = "512mb"
  private_networking = false
  ssh_keys = [
    "${var.ssh_fingerprint}"
  ]
  connection {
    user = "root"
    type = "ssh"
    private_key = "${file("${var.pvt_key}")}"
    timeout = "2m"
  }
  provisioner "local-exec" {
    command = "provision/tlsgen-base.sh"
  }
  provisioner "local-exec" {
    command = "provision/tlsgen-base.sh"
  }
  provisioner "local-exec" {
    command = "provision/tlsgen-node.sh ${self.ipv4_address}"
  }
  provisioner "file" {
    source = "keys/ca.pem"
    destination = "/tmp/ca.pem"
  }
  provisioner "file" {
    source = "keys/${self.ipv4_address}/server-cert.pem"
    destination = "/tmp/server-cert.pem"
  }
  provisioner "file" {
    source = "keys/${self.ipv4_address}/server-key.pem"
    destination = "/tmp/server-key.pem"
  }
  provisioner "remote-exec" {
    scripts = [
      "provision/docker.sh",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "docker swarm init --listen-addr 0.0.0.0:2377 --advertise-addr ${self.ipv4_address}",
      "docker swarm join-token -q manager > /tmp/manager.token",
      "docker swarm join-token -q worker > /tmp/worker.token",
    ]
  }
  provisioner "local-exec" {
    command = "scp -i ${var.pvt_key} -o 'StrictHostKeyChecking no' root@${self.ipv4_address}:/tmp/*.token keys/"
  }
}

resource "digitalocean_droplet" "worker" {
  image = "ubuntu-16-04-x64"
  name = "swarm-worker${count.index}"
  count = 1
  region = "sgp1"
  size = "512mb"
  private_networking = true
  ssh_keys = [
    "${var.ssh_fingerprint}"
  ]
  connection {
    user = "root"
    type = "ssh"
    private_key = "${file("${var.pvt_key}")}"
    timeout = "2m"
  }
  provisioner "local-exec" {
    command = "provision/tlsgen-node.sh ${self.ipv4_address}"
  }
  provisioner "file" {
    source = "keys/ca.pem"
    destination = "/tmp/ca.pem"
  }
  provisioner "file" {
    source = "keys/worker.token"
    destination = "/tmp/worker.token"
  }
  provisioner "file" {
    source = "keys/${self.ipv4_address}/server-cert.pem"
    destination = "/tmp/server-cert.pem"
  }
  provisioner "file" {
    source = "keys/${self.ipv4_address}/server-key.pem"
    destination = "/tmp/server-key.pem"
  }
  provisioner "remote-exec" {
    scripts = [
      "provision/docker.sh",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "docker swarm join --token $(cat /tmp/worker.token) ${digitalocean_droplet.leader.ipv4_address}:2377",
    ]
  }
}
