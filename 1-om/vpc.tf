# VPC/subnet lookups used when aws_config.vpc_id/subnet_id are not provided.
# By validation in variables.tf they are either both set or both null.

# Prefer the default VPC; when the account has none, fall back to the first VPC in the region.
data "aws_vpcs" "default" {
  count = var.aws_config.vpc_id == null ? 1 : 0

  filter {
    name   = "isDefault"
    values = ["true"]
  }
}

data "aws_vpcs" "all" {
  count = var.aws_config.vpc_id == null ? 1 : 0
}

# Public subnets (auto-assign public IP) of the chosen VPC.
data "aws_subnets" "fallback" {
  count = var.aws_config.subnet_id == null ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.fallback_vpc_id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

locals {
  fallback_vpc_id    = length(data.aws_vpcs.default[0].ids) > 0 ? data.aws_vpcs.default[0].ids[0] : element(sort(data.aws_vpcs.all[0].ids), 0)
  fallback_subnet_id = element(sort(data.aws_subnets.fallback[0].ids), 0)
}
