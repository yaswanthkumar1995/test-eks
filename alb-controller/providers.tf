terraform {
  required_providers {

    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }

    tls = { 
      source = "hashicorp/tls" 
      version = "~> 3.0.0" 
    }
    
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.12.1"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
  profile = "naveen-terraform"
  ignore_tags {
    key_prefixes = ["kubernetes.io/"]
  }
}


provider "kubernetes" {
  host                   = var.eks_cluster_endpoint
  cluster_ca_certificate = base64decode("${var.eks_cluster_certificate_data}")
  exec {
    api_version = "client.authentication.k8s.io/v1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}
