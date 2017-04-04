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
  depends_on = [
    "null_resource.tls_base",
  ]
  connection {
    user = "root"
    type = "ssh"
    private_key = "${file(var.ssh_private_key)}"
    timeout = "2m"
  }
  provisioner "local-exec" {
    command = "./provisions/tlsgen-node.sh ${self.ipv4_address}"
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
      "./provisions/docker.sh",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo docker swarm init --listen-addr 0.0.0.0:2377 --advertise-addr ${self.ipv4_address}",
      "sudo docker swarm join-token -q manager > /tmp/manager.token",
      "sudo docker swarm join-token -q worker > /tmp/worker.token",
    ]
  }
  provisioner "local-exec" {
    command = "scp -i ${var.ssh_private_key} -o 'StrictHostKeyChecking no' root@${self.ipv4_address}:/tmp/*.token keys/"
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
  depends_on = [
    "null_resource.tls_base",
    "digitalocean_droplet.leader",
  ]
  connection {
    user = "root"
    type = "ssh"
    private_key = "${file("${var.ssh_private_key}")}"
    timeout = "2m"
  }
  provisioner "local-exec" {
    command = "./provisions/tlsgen-node.sh ${self.ipv4_address}"
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
      "./provisions/docker.sh",
    ]
  }
  provisioner "file" {
    source = "keys/worker.token"
    destination = "/tmp/worker.token"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo docker swarm join --token $(cat /tmp/worker.token) ${digitalocean_droplet.leader.ipv4_address}:2377",
    ]
  }
}
