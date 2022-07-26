variable "aws_region_name" {
  type        = string
  default    = "ap-south-1"
}

variable "cluster_name" {
  type        = string
  default    = "eks-terraform"
}

variable "k8s_namespace" {
  description = "Kubernetes namespace to deploy the AWS ALB Ingress Controller into."
  type        = string
  default     = "kube-system"
}

variable "aws_alb_ingress_controller_version" {
  description = "The AWS ALB Ingress Controller version to use"
  type        = string
  default     = "2.4.2"
}

variable "k8s_pod_annotations" {
  description = "Additional annotations to be added to the Pods."
  type        = map(string)
  default     = {}
}

variable "k8s_pod_labels" {
  description = "Additional labels to be added to the Pods."
  type        = map(string)
  default     = {}
}
