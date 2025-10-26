module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "three-tier-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_eks_cluster" "eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = module.vpc.private_subnets
    endpoint_private_access = true
    endpoint_public_access  = true              # Enable public access to true to reach from local 
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_clsuter_ploicy_attachment,
    awsaws_iam_role.eks_role
  ]
  
}

resource "aws_eks_node_group" "ng" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "var.node_group_name"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = var.node_desired_capacity
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["var.node_instance_type"]

  depends_on = [
    aws_eks_cluster.eks,
    aws_iam.role.node_role,
    aws_iam_role_policy_attachment.node_policy
  ]
  
}