//provider "google" {
//  credentials = "${file(var.gc_credentials)}"
//  project = "${var.gc_project}"
//  region = "${var.gc_region}"
//}
//
//resource "google_compute_firewall" "firewall" {
//  name = "firewall"
//  network = "default"
//  allow {
//    protocol = "tcp"
//    ports = ["80", "443", "2376-2377", "7946"]
//  }
//  allow {
//    protocol = "udp"
//    ports = ["4789", "7946"]
//  }
//  allow {
//    protocol = "icmp"
//  }
//  target_tags = ["swarm-node"]
//  source_ranges = ["0.0.0.0/0"]
//}
//
//resource "google_compute_instance" "manager" {
//  name = "swarm-manager"
//  machine_type = "f1-micro"
//  zone = "asia-east1-a"
//  tags = ["swarm-node"]
//  disk {
//    image = "ubuntu-1510-wily-v20151114"
//  }
//  network_interface {
//    network = "default"
//    access_config {
//      // Ephemeral IP
//    }
//  }
//  metadata {
//    sshKeys = "ubuntu:${file(var.ssh_public_key)}"
//  }
//  connection {
//    user = "ubuntu"
//    type = "ssh"
//    private_key = "${file(var.ssh_private_key)}"
//    timeout = "2m"
//  }
//  depends_on = ["null_resource.tls_base"]
//  provisioner "local-exec" {
//    command = "provisions/tlsgen-node.sh ${self.network_interface.0.access_config.0.assigned_nat_ip}"
//  }
//  provisioner "file" {
//    source = "keys/ca.pem"
//    destination = "/tmp/ca.pem"
//  }
//  provisioner "file" {
//    source = "keys/${self.network_interface.0.access_config.0.assigned_nat_ip}/server-cert.pem"
//    destination = "/tmp/server-cert.pem"
//  }
//  provisioner "file" {
//    source = "keys/${self.network_interface.0.access_config.0.assigned_nat_ip}/server-key.pem"
//    destination = "/tmp/server-key.pem"
//  }
//  provisioner "remote-exec" {
//    scripts = [
//      "provisions/docker.sh",
//    ]
//  }
//  provisioner "file" {
//    source = "keys/manager.token"
//    destination = "/tmp/manager.token"
//  }
//  provisioner "remote-exec" {
//    inline = [
//      "sudo docker swarm join --token $(cat /tmp/manager.token) ${digitalocean_droplet.leader.ipv4_address}:2377",
//    ]
//  }
//}
