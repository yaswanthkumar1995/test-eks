########################### VPC ###################################
resource "aws_vpc" "vpc-for-eks" {
  cidr_block       = "11.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = "true"
  enable_dns_support = "true"

  tags = {
    Name = "vpc-for-eks"
  }
}

############################ VPC-SUBNETS #########################
resource "aws_subnet" "pubsub1" {
  vpc_id     = aws_vpc.vpc-for-eks.id
  cidr_block = "11.0.0.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "pubsub1"
   "kubernetes.io/cluster/${var.cluster_name}" = "owned"
   "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "pubsub2" {
  vpc_id     = aws_vpc.vpc-for-eks.id
  cidr_block = "11.0.1.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "pubsub2"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "pubsub3" {
  vpc_id     = aws_vpc.vpc-for-eks.id
  cidr_block = "11.0.2.0/24"
  availability_zone = "ap-south-1c"

  tags = {
    Name = "pubsub3"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "pvtsub1" {
  vpc_id     = aws_vpc.vpc-for-eks.id
  cidr_block = "11.0.3.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "pvtsub1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "pvtsub2" {
  vpc_id     = aws_vpc.vpc-for-eks.id
  cidr_block = "11.0.4.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "pvtsub2"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb" = "1"

  }
}

resource "aws_subnet" "pvtsub3" {
  vpc_id     = aws_vpc.vpc-for-eks.id
  cidr_block = "11.0.5.0/24"
  availability_zone = "ap-south-1c"

  tags = {
    Name = "pvtsub3"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

######################## INTERNET-GATEWAY #########################
resource "aws_internet_gateway" "eks-igw" {
  vpc_id = aws_vpc.vpc-for-eks.id

  tags = {
    Name = "eks-igw"
  }
}

######################## NAT-GATEWAY ###########################
resource "aws_nat_gateway" "eks-nat" {
  allocation_id = aws_eip.eks-nat-eip.id
  subnet_id     = aws_subnet.pubsub1.id

  tags = {
    Name = "eks-nat"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.eks-igw]
}

resource "aws_eip" "eks-nat-eip" {
  vpc              = true

  tags = {
    Name = "eks-nat-eip"
  }
}


########################### ROUTE-TABLE-PUBLIC #########################
resource "aws_route_table" "eks-pub-rt" {
  vpc_id = aws_vpc.vpc-for-eks.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks-igw.id
  }


  tags = {
    Name = "eks-pub-rt"
  }
}


########################## ROUTE-TABLE-PRIVATE ########################
resource "aws_route_table" "eks-pvt-rt" {
  vpc_id = aws_vpc.vpc-for-eks.id

  route {
    cidr_block = aws_subnet.pubsub1.cidr_block
    gateway_id = aws_nat_gateway.eks-nat.id
  }


  tags = {
    Name = "eks-pvt-rt"
  }
}


################ PUBLIC-SUBNET-ASSOSCIATION-ROUTE-TABLE ##################
resource "aws_route_table_association" "pubsub1-rt-assoc" {
  subnet_id      = aws_subnet.pubsub1.id
  route_table_id = aws_route_table.eks-pub-rt.id
}

resource "aws_route_table_association" "pubsub2-rt-assoc" {
  subnet_id      = aws_subnet.pubsub2.id
  route_table_id = aws_route_table.eks-pub-rt.id
}

resource "aws_route_table_association" "pubsub3-rt-assoc" {
  subnet_id      = aws_subnet.pubsub3.id
  route_table_id = aws_route_table.eks-pub-rt.id
}

################ PRIVATE-SUBNET-ASSOSCIATION-ROUTE-TABLE ##################
resource "aws_route_table_association" "pvtsub1-rt-assoc" {
  subnet_id      = aws_subnet.pvtsub1.id
  route_table_id = aws_route_table.eks-pvt-rt.id
}

resource "aws_route_table_association" "pvtsub2-rt-assoc" {
  subnet_id      = aws_subnet.pvtsub2.id
  route_table_id = aws_route_table.eks-pvt-rt.id
}

resource "aws_route_table_association" "pvtsub3-rt-assoc" {
  subnet_id      = aws_subnet.pvtsub3.id
  route_table_id = aws_route_table.eks-pvt-rt.id
}

