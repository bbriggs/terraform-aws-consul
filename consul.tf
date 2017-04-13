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

variable "vpc_security_group_ids" {
  type        = "list"
  description = "List of security group IDs to associate instances with (VPC only)"
}

#######################################
provider "aws" {
  region = "${var.region}"
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
  vpc_security_group_ids = "${var.vpc_security_group_ids}"

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
