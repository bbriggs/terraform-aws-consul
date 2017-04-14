## Variables

variable "availability_zones" {
  type        = "list"
  description = "list of availability zones to use for ELBs"
}

variable "security_groups" {
  type = "list"
  description = "List of additional security groups for the consul cluster"
}

variable "private_subnets" {
  type = "list"
  description = "Subnets ELB should deploy servers into"
}

#######################################

resource "aws_elb" "consul" {
  name               = "${var.prefix}servers-elb"
  availability_zones = "${var.availability_zones}"

  listener {
    instance_port     = 8300
    instance_protocol = "tcp"
    lb_port           = 8300
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8301
    instance_protocol = "tcp"
    lb_port           = 8300
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8302
    instance_protocol = "tcp"
    lb_port           = 8302
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8400
    instance_protocol = "tcp"
    lb_port           = 8400
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8500
    instance_protocol = "tcp"
    lb_port           = 8500
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 8600
    instance_protocol = "tcp"
    lb_port           = 8600
    lb_protocol       = "tcp"
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

resource "aws_iam_role" "consul" {
  name               = "${var.prefix}consul"
  assume_role_policy = "${file("${path.module}/policies/role-ec2.json")}"
}

resource "aws_iam_instance_profile" "consul" {
  name  = "${var.prefix}consul"
  roles = ["${aws_iam_role.consul.name}"]
  depends_on = ["aws_iam_role.consul"]
}

data "template_file" "consul-userdata" {
  template = "${file("${path.module}/templates/bootstrap.sh.tmpl")}"

  variables {
    prefix = "${var.prefix}"
    region = "${var.region}"
  }
}

resource "aws_launch_configuration" "consul" {
  name_prefix          = "${var.prefix}"
  user_data            = "${data.template_file.consul-userdata.rendered}"
  image_id             = "${var.ami}"
  key_name             = "${var.key_name}"
  security_groups      = ["${aws_security_group.consul.id}", "${var.security_groups}"]
  iam_instance_profile = "${aws_iam_instance_profile.consul.id}"
  instance_type        = "${var.instance_type}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "consul-servers" {
  name                      = "${var.prefix}seed"
  max_size                  = "${var.num_instances}"
  min_size                  = "${var.num_instances}"
  desired_capacity          = "${var.num_instances}"
  health_check_grace_period = "300"
  health_check_type         = "EC2"
  launch_configuration      = "${aws_launch_configuration.consul.id}"
  load_balancers            = ["${aws_elb.consul.id}"]
  vpc_zone_identifier       = ["${var.private_subnets}"]

  lifecycle {
    create_before_destroy = true
  }
}
