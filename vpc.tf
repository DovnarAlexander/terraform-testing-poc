module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "poc-vpc"
  cidr = var.vpc_cidr

  azs              = data.aws_availability_zones.available.names
  private_subnets  = [for k, az in data.aws_availability_zones.available.names : cidrsubnet(var.vpc_cidr, 8, format("1%d", k))]
  public_subnets   = [for k, az in data.aws_availability_zones.available.names : cidrsubnet(var.vpc_cidr, 8, format("2%d", k))]
  database_subnets = [for k, az in data.aws_availability_zones.available.names : cidrsubnet(var.vpc_cidr, 8, format("3%d", k))]

  single_nat_gateway     = false
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_vpn_gateway     = false

  tags = var.tags
}
