resource "null_resource" "tls_base" {
  provisioner "local-exec" {
    command = "./provisions/tlsgen-base.sh"
  }
}

resource "digitalocean_droplet" "leader" {
  depends_on = [
    "null_resource.tls_base",
  ]
  image = "ubuntu-16-04-x64"
  name = "swarm-leader"
  region = "sgp1"
  size = "512mb"
  private_networking = true
  ssh_keys = [
    "${var.ssh_fingerprint}"
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
}

resource "null_resource" "swarm_init" {
  depends_on = [
    "digitalocean_droplet.leader",
  ]
  connection {
    host = "${digitalocean_droplet.leader.ipv4_address}"
    user = "root"
    type = "ssh"
    private_key = "${file(var.ssh_private_key)}"
    timeout = "2m"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo docker swarm init --listen-addr 0.0.0.0:2377 --advertise-addr ${digitalocean_droplet.leader.ipv4_address_private}",
    ]
  }
}

resource "null_resource" "swarm_token" {
  depends_on = [
    "null_resource.swarm_init",
  ]
  connection {
    host = "${digitalocean_droplet.leader.ipv4_address}"
    user = "root"
    type = "ssh"
    private_key = "${file(var.ssh_private_key)}"
    timeout = "2m"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo docker swarm join-token --rotate manager",
      "sudo docker swarm join-token --rotate worker",
      "sudo docker swarm join-token -q manager > /tmp/manager.token",
      "sudo docker swarm join-token -q worker > /tmp/worker.token",
    ]
  }
  provisioner "local-exec" {
    command = "scp -i ${var.ssh_private_key} -o 'StrictHostKeyChecking no' root@${digitalocean_droplet.leader.ipv4_address}:/tmp/*.token keys/"
  }
}

resource "digitalocean_droplet" "manager" {
  depends_on = [
    "null_resource.swarm_token",
  ]
  image = "ubuntu-16-04-x64"
  name = "swarm-manger${count.index}"
  count = 0
  region = "sgp1"
  size = "512mb"
  private_networking = true
  ssh_keys = [
    "${var.ssh_fingerprint}"
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
    source = "keys/manager.token"
    destination = "/tmp/manager.token"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo docker swarm join --token $(cat /tmp/manager.token) ${digitalocean_droplet.leader.ipv4_address_private}:2377",
    ]
  }
}

resource "digitalocean_droplet" "worker" {
  depends_on = [
    "null_resource.swarm_token",
  ]
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
      "sudo docker swarm join --token $(cat /tmp/worker.token) ${digitalocean_droplet.leader.ipv4_address_private}:2377",
    ]
  }
}
