# Variables 

variable "ami" {
  type        = "string"
  description = "AMI to use for deploying Consul. Use one based on Ubuntu Trusty."
}

variable "instance_type" {
  type        = "string"
  description = "AWS instance type for Consul servers."
}

variable "key_path" {
  type        = "string"
  description = "Path to SSH key used for configuring instances"
}

variable "key_name" {
  type        = "string"
  description = "Name of SSH key to insert into machine to grant initial access"
}

variable "num_instances" {
  type        = "string"
  description = "Number of consul servers to deploy. Consul advides using odd numbers to avoid stalemate elections."
  default     = "3"
}

variable "prefix" {
  type        = "string"
  description = "Prefix for naming instances"
  default     = "consul-"
}

variable "region" {
  type        = "string"
  description = "AWS region for deploying Consul nodes"
}

variable "subnet_id" {
  type        = "string"
  description = "VPC subnet to launch instance into"
}

variable "user" {
  type = "string"
  description = "Username for connecting to server for remote-exec"
  default = "root"
}

variable "vpc" {
  type        = "string"
  description = "VPC in which to deploy Consul"
}

#######################################
provider "aws" {
  region = "${var.region}"
}

resource "aws_security_group" "consul" {
  name_prefix = "${var.prefix}"
  description = "Allow consul traffic"
  vpc_id = "${var.vpc}"
}

resource "aws_security_group_rule" "ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  security_group_id = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_rpc" {
  type = "ingress"
  from_port = "8300"
  to_port = "8300"
  protocol = "tcp"
  security_group_id = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_serf_lan" {
  type = "ingress"
  from_port = "8301"
  to_port = "8301"
  protocol = "all"
  security_group_id = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_serf_wan" {
  type = "ingress"
  from_port = "8302"
  to_port = "8302"
  protocol = "all"
  security_group_id = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_cli_rpc" {
  type = "ingress"
  from_port = "8400"
  to_port = "8400"
  protocol = "tcp"
  security_group_id = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_http_api" {
  type = "ingress"
  from_port = "8500"
  to_port = "8500"
  protocol = "tcp"
  security_group_id = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "consul_dns_interface" {
  type = "ingress"
  from_port = "8600"
  to_port = "8600"
  protocol = "all"
  security_group_id = "${aws_security_group.consul.id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type = "egress"
  from_port = "0"
  to_port = "0"
  protocol = "-1"
  security_group_id = "${aws_security_group.consul.id}"
}
resource "aws_instance" "consul" {
  count                  = "${var.num_instances}"
  name                   = "${var.prefix}${count.index + 1}"
  ami                    = "${var.ami}"
  availability_zone      = "${var.region}"
  instance_type          = "${var.instance_type}"
  key_name               = "${var.key_name}"
  region                 = "${var.region}"
  subnet_id              = "${var.subnet_id}"
  vpc_security_group_ids = ["${aws_security_group.consul.id}"]

  connection {
    type        = "ssh"
    private_key = "${file("${var.key_path}")}"
    user        = "${var.user}"
    timeout     = "2m"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/debian_upstart.conf"
    destination = "/tmp/upstart.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.num_instances} > /tmp/consul-server-count",
      "echo ${aws_instance.consul.0.private_ip} > /tmp/consul-server-addr",
    ]
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../../shared/scripts/consul_install.sh",
      "${path.module}/../../shared/scripts/consul_service.sh",
      "${path.module}/../../shared/scripts/consul_ip_tables.sh",
    ]
  }
}
