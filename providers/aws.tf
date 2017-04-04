//provider "aws" {
//  access_key = "${var.aws_access_key}"
//  secret_key = "${var.aws_secret_key}"
//  region = "${var.aws_default_region}"
//}
//
//resource "aws_key_pair" "my_key_pair" {
//  key_name = "my_key_pair"
//  public_key = "${file(var.ssh_public_key)}"
//}
//
//resource "aws_vpc" "vpc_swarm" {
//  cidr_block = "192.168.0.0/16"
//  instance_tenancy = "default"
//  enable_dns_support = "true"
//  enable_dns_hostnames = "false"
//  tags {
//    Name = "swarm"
//  }
//}
//
//resource "aws_subnet" "vpc_swarm_public_a" {
//  vpc_id = "${aws_vpc.vpc_swarm.id}"
//  cidr_block = "192.168.0.0/24"
//  availability_zone = "ap-northeast-1a"
//  map_public_ip_on_launch = true
//}
//
//resource "aws_internet_gateway" "vpc_swarm_gateway" {
//  vpc_id = "${aws_vpc.vpc_swarm.id}"
//}
//
//resource "aws_route_table" "vpc_swarm_public_route" {
//  vpc_id = "${aws_vpc.vpc_swarm.id}"
//  route {
//    cidr_block = "0.0.0.0/0"
//    gateway_id = "${aws_internet_gateway.vpc_swarm_gateway.id}"
//  }
//}
//
//resource "aws_route_table_association" "vpc_swarm_route_public_a_association" {
//  subnet_id = "${aws_subnet.vpc_swarm_public_a.id}"
//  route_table_id = "${aws_route_table.vpc_swarm_public_route.id}"
//}
//
//resource "aws_security_group" "vpc_swarm_security_allow_ssh" {
//  name = "vpc_swarm_security_allow_ssh"
//  vpc_id = "${aws_vpc.vpc_swarm.id}"
//  ingress {
//    from_port = 22
//    to_port = 22
//    protocol = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//  egress {
//    from_port = 0
//    to_port = 0
//    protocol = "-1"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//}
//
//resource "aws_security_group" "vpc_swarm_security_allow_http" {
//  name = "vpc_swarm_security_allow_http"
//  vpc_id = "${aws_vpc.vpc_swarm.id}"
//  ingress {
//    from_port = 80
//    to_port = 80
//    protocol = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//  ingress {
//    from_port = 443
//    to_port = 443
//    protocol = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//  egress {
//    from_port = 0
//    to_port = 0
//    protocol = "-1"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//}
//
//resource "aws_security_group" "vpc_swarm_security_allow_docker" {
//  name = "vpc_swarm_security_allow_docker"
//  vpc_id = "${aws_vpc.vpc_swarm.id}"
//  ingress {
//    from_port = 2376
//    to_port = 2377
//    protocol = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//  ingress {
//    from_port = 7946
//    to_port = 7946
//    protocol = "tcp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//  ingress {
//    from_port = 4789
//    to_port = 4789
//    protocol = "udp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//  ingress {
//    from_port = 7946
//    to_port = 7946
//    protocol = "udp"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//  egress {
//    from_port = 0
//    to_port = 0
//    protocol = "-1"
//    cidr_blocks = ["0.0.0.0/0"]
//  }
//}
//
//resource "aws_instance" "manager" {
//  key_name = "swarm-manager"
//  ami = "ami-1bfdb67c"
//  instance_type = "t2.nano"
//  key_name = "${aws_key_pair.my_key_pair.key_name}"
//  vpc_security_group_ids = [
//    "${aws_security_group.vpc_swarm_security_allow_ssh.id}",
//    "${aws_security_group.vpc_swarm_security_allow_http.id}",
//    "${aws_security_group.vpc_swarm_security_allow_docker.id}",
//  ]
//  subnet_id = "${aws_subnet.vpc_swarm_public_a.id}"
//  associate_public_ip_address = true
//  root_block_device = {
//    volume_type = "gp2"
//    volume_size = "8"
//  }
//  connection {
//    type = "ssh"
//    user = "ubuntu"
//    host = "${self.public_ip}"
//    private_key = "${file(var.ssh_private_key)}"
//  }
//  depends_on = ["null_resource.tls_base"]
//  provisioner "local-exec" {
//    command = "provisions/tlsgen-node.sh ${self.public_ip}"
//  }
//  provisioner "file" {
//    source = "keys/ca.pem"
//    destination = "/tmp/ca.pem"
//  }
//  provisioner "file" {
//    source = "keys/${self.public_ip}/server-cert.pem"
//    destination = "/tmp/server-cert.pem"
//  }
//  provisioner "file" {
//    source = "keys/${self.public_ip}/server-key.pem"
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
