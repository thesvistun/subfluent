provider "aws" {
  default_tags {
    tags = {
      Project     = "subfluent"
      Environment = "stage"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "block-device-mapping.volume-size"
    values = ["8"]
  }

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "subfluent"
  cidr = "10.0.0.0/16"

  azs             = ["eu-north-1a"]
  private_subnets = ["10.0.1.0/24"]
  public_subnets  = ["10.0.2.0/24"]

  enable_nat_gateway = false
}

resource "aws_security_group" "ssh" {
  name   = "ssh"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.user_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "subfluent" {
  name   = "subfluent"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["${var.user_ip}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_key_pair" "default" {
  key_name = "default"
}

module "web" {
  source = "./modules/ec2"

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  subnet_id = module.vpc.public_subnets[0]

  security_group_ids = [aws_security_group.ssh.id, aws_security_group.subfluent.id]

  key_name = data.aws_key_pair.default.key_name

  name = "subfluent"
}

data "ansible_inventory" "inventory" {
  group {
    name = "subfluent"

    host {
      name = module.web.instance_hostname
    }
  }
}

resource "local_file" "inventory" {
  content  = jsonencode(jsondecode(data.ansible_inventory.inventory.json))
  filename = "inventory.yaml"
}
