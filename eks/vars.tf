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
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC09Q0JaLCpN3MtzSzVezHPo3rtPczZrNxSOZIlt6lk749Tx1vheMB0+xCrphmhjMrgUl88v3zC0MftD8LqHM3hQvVxvFOqxWZuCyZ1T9Kek1XSdV9+v+tbmCK76k7+ANtecKaIpvDBp8F+4HuOWY9E9Kqm9NK1ItUYSmS/Jj1JiG0cAhsdhu0vExLXv0fZRGl52p/mAmgV/5ydKQ0v0vzqXkG3RzFcuisejR5AkdaDkYw+U0K6jdea6e1FR7lX3W3zFTEpHu3TGtFqyroPd2cAv4Ic00fz+1KfPdfU2puBuUbETmC9rvwRgNotBzJPlZiJiyp+eQSQfgjP5svplwKb2RwTBl1AvWtCz3HvvKtRZWsgRvLf5LHZ0+VrjJpIJu4dByZcKLoZie5drwKsgTR/TRwPKROR7dC+UWmgCSKKFhKtfAmqetkdpk5Ae4P6pSRG06RKvm96emaUxEFUUcl10KIwpGUHP966dY1Bh9nXs1HePKalYx5NhBKrIJvlsoc= RACKSPACE+yasw2846@AAD-DP3GZH3"
}

variable "bastion_ssh_cidr_block" {
  description = "bastion host cidr_block to ssh"
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "bastion host instance type"
  default     = "t2.micro"
}
