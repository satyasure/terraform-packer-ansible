data "aws_ami" "windows-ami" {
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-2021*"]
  }
  filter {
    name   = "platform"
    values = ["windows"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  most_recent = true
  owners      = ["amazon"]
}

data "aws_ami" "ubuntu" {

    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["amazon"]
}
