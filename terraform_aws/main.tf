# Step 1: VPC Creation

resource "aws_vpc" "ansible-terraform-vpc" {
  cidr_block = "10.0.0.0/27"
}

# Step 2: Subnets Creation
resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.ansible-terraform-vpc.id
  cidr_block              = "10.0.0.0/28"
  map_public_ip_on_launch = "true"
  availability_zone       = "eu-west-3a"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.ansible-terraform-vpc.id
  cidr_block              = "10.0.0.16/28"
  map_public_ip_on_launch = "false"
  availability_zone       = "eu-west-3a"

  tags = {
    Name = "private-subnet"
  }
}

# Step 3: Internet Gateway Creation
resource "aws_internet_gateway" "internet-gw" {
  vpc_id = aws_vpc.ansible-terraform-vpc.id

  tags = {
    Name = "internet-gw"
  }
}

# Step 4: Public route table and association Creation

resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.ansible-terraform-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gw.id
  }
}

resource "aws_route_table_association" "public-rta" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

# Step 5: Nat Gateway with Elastic IP route table and association 
resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_nat_gateway" "nat-gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-subnet.id
  depends_on    = [aws_internet_gateway.internet-gw]
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.ansible-terraform-vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }
}

resource "aws_route_table_association" "private-rta" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rt.id
}

# Step 6: Security Groups Creation for SSH connection allow

resource "aws_security_group" "allow-ssh" {
  vpc_id = aws_vpc.ansible-terraform-vpc.id
  name        = "allow-ssh"
  description = "security group that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow-ssh"
  }
}

# Step 7: Key Pair Creation

## Generate SSH key content using terraform

resource "tls_private_key" "user-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ansible-terraform" {
  key_name   = var.ansible-terraform_name
  public_key = tls_private_key.user-key.public_key_openssh

  provisioner "local-exec" {    # Generate "terraform-key-pair.pem" in current directory
    command = <<-EOT
      echo '${tls_private_key.user-key.private_key_pem}' > ./'${var.ansible-terraform_name}'.pem
      chmod 400 ./'${var.ansible-terraform_name}'.pem
    EOT
  }

}
# Step 8: Instance Creation

resource "aws_instance" "bastion-instance" {
  ami           = data.aws_ami.ubuntu
  instance_type = var.instance_type
  subnet_id = aws_subnet.public-subnet.id
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  key_name = aws_key_pair.ansible-terraform.key_name
  tags = {
    Name = "bastion-instance"
  }
}

resource "aws_instance" "private-instance" {
  ami           = data.aws_ami.ubuntu
  instance_type = var.instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  subnet_id = aws_subnet.private-subnet.id
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]
  key_name = aws_key_pair.ansible-terraform.key_name
    tags = {
    Name = "private-instance"
  }
}
