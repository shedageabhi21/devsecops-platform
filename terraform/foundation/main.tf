terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "abhishek-my-lab-bucket-for-tfe"
    key          = "devsecops/foundation/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    encrypt      = true
  }
}

provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      Project   = "devsecops"
      ManagedBy = "terraform"
    }
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "devsecops-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway      = true
  single_nat_gateway      = true
  enable_dns_hostnames    = true
  map_public_ip_on_launch = true

  # Lets EKS and load balancers find the subnets later
  public_subnet_tags = {
    "kubernetes.io/cluster/devsecops-eks" = "shared"
    "kubernetes.io/role/elb"              = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/devsecops-eks" = "shared"
    "kubernetes.io/role/internal-elb"     = "1"
  }
}

resource "aws_ecr_repository" "app" {
  name                 = "todo-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
