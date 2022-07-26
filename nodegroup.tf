###################### NODE-GROUP ##########################
resource "aws_eks_node_group" "eks_nodegroup" {
  cluster_name    = aws_eks_cluster.eks_terraform.name
  node_group_name = "ng"
  node_role_arn   = aws_iam_role.eks_nodegroup_role.arn
  subnet_ids      = [ aws_subnet.pvtsub1.id, aws_subnet.pvtsub2.id, aws_subnet.pvtsub3.id ]
  remote_access {
  	source_security_group_ids = [ aws_security_group.eks_nodegroup_allow_ssh.id ]
        ec2_ssh_key = aws_key_pair.eks-nodegrup-sshkey.key_name
  }
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_terraform-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_terraform-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_terraform-AmazonEC2ContainerRegistryReadOnly,
    aws_eks_addon.vpc-cni
  ]
}

resource "aws_key_pair" "eks-nodegrup-sshkey" {
  key_name   = "eksnodegroupsshkey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDQv/6InbBo9XQmSdNvTKe8zk2rEOkxSm6JbVFnchxBlaoUBUxhf4qYqjqlGaED7IoT32+7rbcJoAdUvSEnhqfT3C6iaNvT3LB7Nfpv0IhipCxGORspk5wIvA1zmFZWsqCue58GeneYZ/x8IA59IsH/196utj7ppFx5vYVy6/JjyZ3xfW1liELtjXy3hk/XN7/4UVs162nhktylK3V55TAQAAGF/vNBUeVLvTEmogvZdgMkEetrXHjSlBfiaFjX58DClV6NJGg+MN85BjkMTskk/KEGdgz2WqN0Z39ICFS8dhYfXyGdEIBnFm39osnj6vq+HWRNroWyTAvX//X0RZVcRjXuZ5FkaEJHySXQTlwJfiXc8xykGQgC+vbMsEbJsJODncawYo1Y0h8zAO2c+kd94xIJj3kTVyhQ31lZQfgHGM/JP8B+AmSaFA9JkgCWn94N0Uh9K7HUZhWJ1oRYT+bryGCydG5sRo6+FLyMSB6jRYHe+9hE900Xc6TlehtXGoE= naveen@naveen-Latitude-E5450"
}
###################### NODE-GROUP-ACCESS-SECUROTY-GROUP ############################
resource "aws_security_group" "eks_nodegroup_allow_ssh" {
  name        = "eks_nodegroup_allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.vpc-for-eks.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.vpc-for-eks.cidr_block]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

######################## NODE-GROUP-ROLE ###########################
resource "aws_iam_role" "eks_nodegroup_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_terraform-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks_terraform-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodegroup_role.name
}

resource "aws_iam_role_policy_attachment" "eks_terraform-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodegroup_role.name
}

