# Variables 

variable "ami" {
  type        = "string"
  description = "AMI to use for deploying Consul. Use one based on Ubuntu Trusty."
}

variable "instance_type" {
  type        = "string"
  description = "AWS instance type for Consul servers."
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
  vpc_id      = "${var.vpc}"
}

resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = "${aws_security_group.consul.id}"
  self              = true
}

resource "aws_security_group_rule" "consul_rpc" {
  type              = "ingress"
  from_port         = "8300"
  to_port           = "8300"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.consul.id}"
  self              = "true"
}

resource "aws_security_group_rule" "consul_serf_lan" {
  type              = "ingress"
  from_port         = "8301"
  to_port           = "8301"
  protocol          = "all"
  security_group_id = "${aws_security_group.consul.id}"
  self              = true
}

resource "aws_security_group_rule" "consul_serf_wan" {
  type              = "ingress"
  from_port         = "8302"
  to_port           = "8302"
  protocol          = "all"
  security_group_id = "${aws_security_group.consul.id}"
  self              = true
}

resource "aws_security_group_rule" "consul_cli_rpc" {
  type              = "ingress"
  from_port         = "8400"
  to_port           = "8400"
  protocol          = "tcp"
  security_group_id = "${aws_security_group.consul.id}"
  self              = true
}

resource "aws_security_group_rule" "consul_dns_interface" {
  type              = "ingress"
  from_port         = "8600"
  to_port           = "8600"
  protocol          = "all"
  security_group_id = "${aws_security_group.consul.id}"
  self              = true
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = "0"
  to_port           = "0"
  protocol          = "-1"
  security_group_id = "${aws_security_group.consul.id}"
  cidr_blocks       = ["0.0.0.0/0"]
}
