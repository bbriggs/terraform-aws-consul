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

### The big catch: Freaking AWS metadata magic, yo

This is a pretty straightforward module except for one thing: the userdata. Inside the userdata, we are running a small script that installs AWS cli and depends on a package called `jq` to parse our JSON response from AWS. We grab all the running instances with the Name tag set to a value of 'consul' (to be paramaterized in upcoming commits). This exposes all the other machines in the ASG and lets us find our peers. 

Because this module was built with Vault in mind, the complimentary Vault module also looks for the Consul members using `aws ec2 describe-instances`.

### Contributing

Send PRs straight to master. YOLO. Feel free to open issues or reach out to me on Gitter in the Vault, Consul, and Terraform rooms.
