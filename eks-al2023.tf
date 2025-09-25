module "eks_al2023" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.cluster_name}-al2023"
  kubernetes_version = "1.33"
  endpoint_public_access = true

  # EKS Addons
  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    one = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      name           = "database"
      instance_types = [var.database_instance_type_db]
      ami_type       = var.ami_type

      min_size = 2
      max_size = 5
      # This value is ignored after the initial creation
      # https://github.com/bryantbiggs/eks-desired-size-hack
      desired_size = 2
             labels = {
       "mission-control.datastax.com/role" = "database"}
      # This is not required - demonstrates how to pass additional configuration to nodeadm
      # Ref https://awslabs.github.io/amazon-eks-ami/nodeadm/doc/api/
      cloudinit_pre_nodeadm = [
        {
          content_type = "application/node.eks.aws"
          content      = <<-EOT
            ---
            apiVersion: node.eks.aws/v1alpha1
            kind: NodeConfig
            spec:
              kubelet:
                config:
                  shutdownGracePeriod: 30s
          EOT
        }
      ]
    },
    two = {
        name           = "platform"
        instance_types = [var.platform_instance_type_db]
        ami_type       = var.ami_type
  
        min_size     = 1
        max_size     = 3
        desired_size = 3
  
        additional_tags = {
          Name = "${var.cluster_name}-al2023-ng-two"
        }
        labels = {"mission-control.datastax.com/role" = "platform"}
      }
  }

  tags = local.tags
}

data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks_al2023.cluster_name}"
  provider_url                  = module.eks_al2023.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}


provider "kubernetes" {
    host                   = module.eks_al2023.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks_al2023.cluster_certificate_authority_data)

    # Configure authentication using AWS CLI for EKS cluster
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", "${var.cluster_name}-al2023"]
      command     = "aws"
    }  
}

# if no default storage class is configured none of the persitent volume claims (pvcs) will mount on the cluster 
resource "kubernetes_annotations" "set_default_storage" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
  metadata {
    name = "gp2"
  }
  # These annotations will be applied to the StorageClass resource itself
  annotations = {
    "storageclass.kubernetes.io/is-default-class" = "true"
  }
  depends_on=[module.eks_al2023.cluster_name]
}

# This is calling out on the host computer to Kubernetes - this sets this cluster on the host machine to be in the current context - if you don't have Kubernetes installed this will fail 
resource "null_resource" "kubectl" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.region} update-kubeconfig --name ${var.cluster_name}-al2023"
  }
  depends_on = [module.eks_al2023]
}

