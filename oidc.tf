########################## CLUSTER-OIDC-PROVIDER ####################
data "tls_certificate" "eks_terraform" {
  url = aws_eks_cluster.eks_terraform.identity[0].oidc[0].issuer
  depends_on = [
    aws_eks_cluster.eks_terraform
  ]
}

resource "aws_iam_openid_connect_provider" "eks_oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_terraform.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks_terraform.identity[0].oidc[0].issuer
  depends_on = [
    aws_eks_cluster.eks_terraform
  ]
}



data "aws_iam_policy_document" "AWSLoadBalancerControllerIAMPolicy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks_oidc_provider.arn]
      type        = "Federated"
    }
  }
}
