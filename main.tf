provider "aws" {
    region = "eu-west-3"
    profile = "default"
  
}
resource "aws_vpc" "dev-vpc" {
    cidr_block = "10.0.0.0/16"
    tags = {
      "Name" = "${var.dev-vpc}"
    }
}

variable "dev-vpc" {
  type = string
  description = "Environment"
  default = "development"
}