data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ssm_parameter" "db_user" {
  name = "/PoC/database/admin_user"
}

data "aws_ssm_parameter" "db_password" {
  name = "/PoC/database/admin_password"
}

data "aws_ssm_parameter" "ssh_public" {
  name = "/PoC/ec2/ssh_public"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
