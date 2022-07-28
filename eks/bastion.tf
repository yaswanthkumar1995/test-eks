resource "aws_instance" "bastion" {
  ami                         = "ami-08df646e18b182346"
  subnet_id                   = aws_subnet.pubsub1.id
  key_name                    = var.ssh_keypair_name
  instance_type               = var.instance_type
  vpc_security_group_ids      = ["${aws_security_group.bastion-sg.id}"]
  associate_public_ip_address = true
}


resource "aws_security_group" "bastion-sg" {
  name        = "bastion_host_sg_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.vpc-for-eks.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [var.bastion_ssh_cidr_block]
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

resource "aws_key_pair" "deployer" {
  key_name   = var.ssh_keypair_name
  public_key = var.public_key
}
