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




##################### BASTION HOST VARIABLES #########################
variable "ssh_keypair_name" {
  description = "bastion host keypair"
  default     = "eks-bastion"
}

variable "public_key" {
  description = "bastion host publickey"
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCy4fGA/UApqeur96T1hj0g/XfLwlONiwrOReCdFIDcEP4qLjjxg5LY28BI4FQ5dmbfvqJEBEYBNKSwKduyUJVFh0RALdiMPIyv8qoy7vu0lwuwNDSeCcMriXAAE/Bt3TBOnZJ4wlwR1yXO1CHuo0XuTSk/9ChQOWXZ5Mm0Q5PLwZ6jtPC1168M13eMoi8pgc2CR63LnCU6tjNSue3O5oaK+JzXDImroTbF40qTblFTJAtSZn9Se/g0yHIDw/8F5vNsc/QbOJrfI+2VapuaBEKp9P9LsfyELEWDa0ODUjiERjFMLUQrGp01TFoViHkzJEoa71omzOsQbZSuKhqdlh5gCbTY+w3XHS3UgJOPnZZnN6R+c3VPhwPzr+5Mq0IuSUKCkXlwr7yCW/M39qpRseRcSC7gYGdMKQ1GSxjGwwQ/pJOeKpPuVgSNQPX5jTzYAIYxDwE1bfCrKxf0QDm9WlGUVVCF/H9o6whj8V+IKfa1YnzbVyhL9mV7D9wTR4OIImU= naveen@naveen-Latitude-E5450"
}

variable "bastion_ssh_cidr_block" {
  description = "bastion host cidr_block to ssh"
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "bastion host instance type"
  default     = "t2.micro"
}
