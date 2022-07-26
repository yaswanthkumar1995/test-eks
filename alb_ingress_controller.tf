resource "aws_iam_policy" "AWSLoadBalancerControllerIAMPolicy" {

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
		"Federated": "$(aws_iam_openid_connect_provider.eks_oidc_provider.arn)"
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
  depends_on = [aws_iam_openid_connect_provider.eks_oidc_provider]
}

resource "aws_iam_policy_attachment" "ALBControllerRole-policy-attachment" {
  name       = "ALBControllerRole-policy-attachment"
  roles      = ["${aws_iam_role.AmazonEKSLoadBalancerControllerRole.name}"]
  policy_arn = "${aws_iam_policy.AWSLoadBalancerControllerIAMPolicy.arn}"
}

resource "kubernetes_service_account" "aws-load-balancer-controller-service-account" {
  automount_service_account_token = true
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.AmazonEKSLoadBalancerControllerRole.arn
    }
    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/component"  = "controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  depends_on = [aws_eks_node_group.eks_nodegroup]
}



resource "kubernetes_cluster_role" "cluster-role-contoller" {
  metadata {
    name = "aws-load-balancer-controller"

    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  rule {
    api_groups = [
      "",
      "extensions",
    ]

    resources = [
      "configmaps",
      "endpoints",
      "events",
      "ingresses",
      "ingresses/status",
      "services",
    ]

    verbs = [
      "create",
      "get",
      "list",
      "update",
      "watch",
      "patch",
    ]
  }

  rule {
    api_groups = [
      "",
      "extensions",
    ]

    resources = [
      "nodes",
      "pods",
      "secrets",
      "services",
      "namespaces",
    ]

    verbs = [
      "get",
      "list",
      "watch",
    ]
  }
  depends_on = [aws_eks_node_group.eks_nodegroup]
}

resource "kubernetes_cluster_role_binding" "cluster-rolebinding-controller" {
  metadata {
    name = "aws-load-balancer-controller"

    labels = {
      "app.kubernetes.io/name"       = "aws-load-balancer-controller"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.cluster-role-contoller.metadata[0].name
  }

  subject {
    api_group = ""
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.aws-load-balancer-controller-service-account.metadata[0].name
    namespace = kubernetes_service_account.aws-load-balancer-controller-service-account.metadata[0].namespace
  }
   depends_on = []
}



resource "kubernetes_deployment" "k8s-alb-controller" {
  depends_on = [kubernetes_cluster_role_binding.cluster-rolebinding-controller]

  metadata {
    name      = "aws-alb-ingress-controller"
    namespace = var.k8s_namespace

    labels = {
      "app.kubernetes.io/name"       = "aws-alb-ingress-controller"
      "app.kubernetes.io/version"    = "v${var.aws_alb_ingress_controller_version}"
      "app.kubernetes.io/managed-by" = "terraform"
    }

    annotations = {
      "field.cattle.io/description" = "AWS ALB Ingress Controller"
    }
  }

  spec {

    replicas = 1

    selector {
      match_labels = {
        "app.kubernetes.io/name" = "aws-alb-ingress-controller"
      }
    }

    strategy {
      type = "Recreate"
    }

    template {
      metadata {
        labels = merge(
          {
            "app.kubernetes.io/name"    = "aws-alb-ingress-controller"
            "app.kubernetes.io/version" = var.aws_alb_ingress_controller_version
          },
          var.k8s_pod_labels
        )
        annotations = merge(
          {
            # Annotation which is only used by KIAM and kube2iam.
            # Should be ignored by your cluster if using IAM roles for service accounts, e.g.
            # when running on EKS.
            "iam.amazonaws.com/role" = aws_iam_role.AmazonEKSLoadBalancerControllerRole.arn
          },
          var.k8s_pod_annotations
        )
      }

      spec {
        affinity {
          pod_anti_affinity {
            preferred_during_scheduling_ignored_during_execution {
              weight = 100
              pod_affinity_term {
                label_selector {
                  match_expressions {
                    key      = "app.kubernetes.io/name"
                    operator = "In"
                    values   = ["aws-alb-ingress-controller"]
                  }
                }
                topology_key = "kubernetes.io/hostname"
              }
            }
          }
        }

        automount_service_account_token = true

        dns_policy = "ClusterFirst"

        restart_policy = "Always"

        container {
          name                     = "server"
          image                    = "amazon/aws-alb-ingress-controller:${var.aws_alb_ingress_controller_version}"
          image_pull_policy        = "Always"
          termination_message_path = "/dev/termination-log"

          args = [
            "--ingress-class=alb",
            "--cluster-name=${var.cluster_name}",
            "--aws-vpc-id=${aws_vpc.vpc-for-eks.id}",
            "--aws-region=${var.aws_region_name}",
            "--aws-max-retries=10",
          ]

          env {
            name  = "AWS_REGION"
            value = var.aws_region_name
          }

          port {
            name           = "health"
            container_port = 10254
            protocol       = "TCP"
          }

          readiness_probe {
            http_get {
              path   = "/healthz"
              port   = "health"
              scheme = "HTTP"
            }

            initial_delay_seconds = 30
            period_seconds        = 60
            timeout_seconds       = 3
          }

          liveness_probe {
            http_get {
              path   = "/healthz"
              port   = "health"
              scheme = "HTTP"
            }

            initial_delay_seconds = 60
            period_seconds        = 60
          }
        }

        service_account_name             = kubernetes_service_account.aws-load-balancer-controller-service-account.metadata[0].name
        termination_grace_period_seconds = 60
      }
    }
  }
}

