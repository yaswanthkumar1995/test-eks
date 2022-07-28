####################### EKS-CLUSTER ###################
resource "aws_eks_cluster" "eks_terraform" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks-iam-role.arn
  vpc_config {
    subnet_ids = [aws_subnet.pvtsub1.id, aws_subnet.pvtsub2.id, aws_subnet.pvtsub3.id]
    security_group_ids = [ aws_security_group.eks_access_sg.id ]
    endpoint_private_access = "true"
    endpoint_public_access = "false"
  }
  enabled_cluster_log_types = ["api", "audit", "scheduler", "authenticator", "controllerManager"]
  depends_on = [
    aws_iam_role_policy_attachment.attach-eks-AmazonEKSClusterPolicy,
    aws_security_group.eks_access_sg
  ]
}

########################### CLUSTER-ADDONS #####################
resource "aws_eks_addon" "vpc-cni" {
  cluster_name = aws_eks_cluster.eks_terraform.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "kube-proxy" {
  cluster_name = aws_eks_cluster.eks_terraform.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.eks_terraform.name
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.eks_nodegroup]
}

#################### CLUSTER-ADDITIONAL-SECURITY-GROUP ####################
resource "aws_security_group" "eks_access_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc-for-eks.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc-for-eks.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}


######################### CLUSTER-ROLE ########################
resource "aws_iam_role" "eks-iam-role" {
  name = "eks-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "attach-eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-iam-role.name
}


resource "aws_cloudwatch_log_group" "eks-cluster-logs" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 7
}


output "endpoint" {
  value = aws_eks_cluster.eks_terraform.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.eks_terraform.certificate_authority[0].data
}
