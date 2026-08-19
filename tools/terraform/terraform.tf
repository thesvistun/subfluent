terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.54"
    }

    ansible = {
      version = "~> 1.5.0"
      source  = "ansible/ansible"
    }
  }

  required_version = ">= 1.15"
}

