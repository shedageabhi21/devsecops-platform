# Read the VPC and subnets created by the foundation stack
data "terraform_remote_state" "foundation" {
  backend = "s3"
  config = {
    bucket = "abhishek-my-lab-bucket-for-tfe"
    key    = "devsecops/foundation/terraform.tfstate"
    region = "ap-south-1"
  }
}

locals {
  cluster_name = "devsecops-eks" # must match the subnet tags in the foundation stack
  vpc_id       = data.terraform_remote_state.foundation.outputs.vpc_id
  subnet_ids   = data.terraform_remote_state.foundation.outputs.private_subnet_ids
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = local.vpc_id
  subnet_ids = local.subnet_ids

  # API reachable only from my IP range, so kubectl and helm run from the VM
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = [var.my_ip]

  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true

  cluster_addons = {
    coredns    = { most_recent = true }
    kube-proxy = { most_recent = true }
    vpc-cni    = { most_recent = true }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      ami_type       = "AL2023_x86_64_STANDARD"

      min_size     = 1
      max_size     = 3
      desired_size = 2

      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size = 30
            volume_type = "gp3"
            encrypted   = true
          }
        }
      }
    }
  }
}

# IAM role for the EBS CSI driver (needed for Prometheus/Grafana volumes)
module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${local.cluster_name}-ebs-csi-driver"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = module.eks.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn

  depends_on = [module.eks]
}
