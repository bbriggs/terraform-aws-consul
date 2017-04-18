# terraform-aws-consul
Terraform module for deploying a consul cluster on AWS

Mostly borrowed from Hashicorp's Terraform examples for Consul and http://engineering.skybettingandgaming.com/2016/05/05/aws-and-consul/

## Usage

### Prerequisites

Deploys a consul cluster in an autoscaling group into an exising VPC within AWS.

Takes an AMI as input, one is not provided or defaulted. Highly recommend using the packer scripts to start the build.

### Example

```terraform
data "aws_ami" "ubuntu-consul" {
  most_recent = true

  filter {
    name   = "name"
    values = ["consul-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["${var.your_aws_account_id}"]
}

module "consul" {
  source = "github.com/bbriggs/terraform-aws-consul"

  ami = "${data.aws_ami.ubuntu-consul.id}"
  availability_zones = ["us-east-1c","us-east-1d","us-east-1e"]
  instance_type = "m3.medium"
  key_name = "${var.EC2_KEY_PAIR}"
  num_instances = "5"
  prefix = "consul-"
  private_subnets = ["${data.some_subnet_1.id}","${data.some_subnet_2.id}","${data.some_subnet_3.id}"]
  region = "${var.REGION}"
  security_groups = ["${data.additional_security_group.id}"]
  vpc = "${data.aws_vpc.your_vpc.id}"
}
```
