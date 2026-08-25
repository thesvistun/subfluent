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

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.6.1"

  name = "subfluent"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 2)
  public_subnets  = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnets = ["10.0.2.0/24", "10.0.4.0/24"]

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
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name   = "alb"
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

## CloudWatch

resource "aws_cloudwatch_log_group" "subfluent" {
  name              = "subfluent"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_stream" "subfluent" {
  name           = "subfluent"
  log_group_name = aws_cloudwatch_log_group.subfluent.name
}

## IAM Role

resource "aws_iam_role" "cloudwatch" {
  name = "cloudwatch"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_attachment" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_instance_profile" "subfluent_profile" {
  name = "subfluent_profile"
  role = aws_iam_role.cloudwatch.name
}

module "web" {
  source = "./modules/ec2"

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  iam_instance_profile_name = aws_iam_instance_profile.subfluent_profile.name

  subnet_id = module.vpc.public_subnets[0]

  security_group_ids = [aws_security_group.ssh.id, aws_security_group.subfluent.id]

  key_name = data.aws_key_pair.default.key_name

  name = "subfluent"
}

## ALB ###################################################

resource "aws_lb" "subfluent" {
  name               = "subfluent"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_target_group" "subfluent" {
  name     = "subfluent"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}

resource "aws_lb_target_group_attachment" "subfluent" {
  target_group_arn = aws_lb_target_group.subfluent.arn
  target_id        = module.web.instance_id
  depends_on = [
    aws_lb_target_group.subfluent,
    module.web,
  ]
}

resource "aws_lb_listener" "subfluent" {
  load_balancer_arn = aws_lb.subfluent.arn
  port              = 8080
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.subfluent.arn
  }
}

## Ansible Inventory #####################################

data "ansible_inventory" "inventory" {
  group {
    name = "subfluent"

    host {
      name = module.web.instance_hostname
    }
    vars = {
      aws_cw_group_name  = aws_cloudwatch_log_group.subfluent.name
      aws_cw_stream_name = aws_cloudwatch_log_stream.subfluent.name
    }
  }
}

resource "local_file" "inventory" {
  content  = yamlencode(jsondecode(data.ansible_inventory.inventory.json))
  filename = "inventory.yaml"
}
