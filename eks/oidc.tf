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


resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {
  name = "${var.cluster_name}-AWSLoadBalancerControllerIAMPolicy"
  policy = "${file("iam_policy.json")}"
}



resource "aws_iam_role" "AmazonEKSLoadBalancerControllerRole" {
  name = "${var.cluster_name}-AmazonEKSLoadBalancerControllerRole"

  assume_role_policy = jsonencode(
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "${aws_iam_openid_connect_provider.eks_oidc_provider.arn}"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "${replace(aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:aud": "sts.amazonaws.com",
                    "${replace(aws_iam_openid_connect_provider.eks_oidc_provider.url, "https://", "")}:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
  }
)
  depends_on = [aws_iam_policy.AWSLoadBalancerControllerIAMPolicy, aws_iam_openid_connect_provider.eks_oidc_provider]
}

resource "aws_iam_policy_attachment" "ALBControllerRole-policy-attachment" {
  name       = "ALBControllerRole-policy-attachment"
  roles      = ["${aws_iam_role.AmazonEKSLoadBalancerControllerRole.name}"]
  policy_arn = "${aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn}"
}

