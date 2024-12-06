resource "aws_key_pair" "eks" {
  key_name   = "eks"
  # you can paste the public key directly like this
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyx6tM9wRwmaMXdXyoMOYcjJosuK/H/1A/flV+BGcuNQco6wbxn17byjGHoAsGUzeoYzVOkehoTlPWbSChE+8qLXyNktxxZwfSdj4LGsDoaBlshsSiFL3mZcC7Nr6xVdE9brAktbmlSFg6C7dsilmYY17mxEL+yThERXIxco71rAxRNyu41jAsVAH1utaj3VUsPzEqvScL93XizBOnav+2uVGMLiH1Eh2AQCLL11hnIBdtgANnWOqOwuIoBOhRUnVaL8ezsZKAFrDPmnNH5FRLQBSI2CgxkujqaGzQJFlgL3jfrJ9lTw9tFVlrOAq2JxaQbzfksIEs7EgLfI9muIyKLPGfRIM1Q7V4/TfNL+oELTGYKxWY15xsGzDeP0YtbMovjQNf+2Yk9y9mU7HRTXVIuVqj5KqIMhlMFToNJDhNTt/v0mcHvUMVK47Uli2XpJpOkKc81guPeTPHrfRAycFrbyMyaqCVFXac+u8gW6lbBvJqXC/7WiXn6Lex9uqogxs= nanda@Nanda_Raju"
  #public_key = file("~/.ssh/eks.pub")
  # ~ means windows home directory
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"


  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = "1.30"

  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}
  }

  vpc_id                   = data.aws_ssm_parameter.vpc_id.value
  subnet_ids               = local.private_subnet_ids
  control_plane_subnet_ids = local.private_subnet_ids

  create_cluster_security_group = false
  cluster_security_group_id     = local.eks_control_plane_sg_id

  create_node_security_group = false
  node_security_group_id     = local.node_sg_id

  # the user which you used to create cluster will get admin access

  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    instance_types = ["m6i.large", "m5.large", "m5n.large", "m5zn.large"]
  }

  eks_managed_node_groups = {
    blue = {
      min_size      = 2
      max_size      = 10
      desired_size  = 2
      #capacity_type = "SPOT"
      iam_role_additional_policies = {
        AmazonEBSCSIDriverPolicy          = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
        AmazonElasticFileSystemFullAccess = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
        ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
      }
      # EKS takes AWS Linux 2 as it's OS to the nodes
      key_name = aws_key_pair.eks.key_name
    }
    # green = {
    #   min_size      = 2
    #   max_size      = 10
    #   desired_size  = 2
    #   #capacity_type = "SPOT"
    #   iam_role_additional_policies = {
    #     AmazonEBSCSIDriverPolicy          = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
    #     AmazonElasticFileSystemFullAccess = "arn:aws:iam::aws:policy/AmazonElasticFileSystemFullAccess"
    #     ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
    #   }
    #   # EKS takes AWS Linux 2 as it's OS to the nodes
    #   key_name = aws_key_pair.eks.key_name
    # }
  }

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  tags = var.common_tags
}