# Shared security group for all EC2 instances created by this tool (1-om and
# 2-clusters). The ec2 module attaches every instance to this group and adds
# the instance public IPs as ingress CIDRs; the base rules below (Terraform
# machine IP + VPC CIDR) are created here, once.
#
# All ingress rules are managed with aws_security_group_rule resources (no
# inline ingress blocks) because the ec2 module adds rules to this same group:
# mixing inline blocks and standalone rule resources on one group makes
# Terraform overwrite the rules.

data "aws_vpc" "selected" {
  id = local.aws_config.vpc_id
}

locals {
  # Base ingress rules of the shared security group: management ports from the
  # machine running Terraform, and the MongoDB port from the VPC CIDR.
  shared_sg_rules = [
    {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = local.my_ip_cidrs
    },
    {
      description = "HTTP access"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = local.my_ip_cidrs
    },
    {
      description = "HTTPS access"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = local.my_ip_cidrs
    },
    {
      description = "Ops Manager web access"
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = local.my_ip_cidrs
    },
    {
      description = "Ops Manager HTTPS access"
      from_port   = 8443
      to_port     = 8443
      protocol    = "tcp"
      cidr_blocks = local.my_ip_cidrs
    },
    {
      description = "MongoDB access"
      from_port   = 27017
      to_port     = 27017
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.selected.cidr_block]
    }
  ]
}

resource "aws_security_group" "shared" {
  # Per-user name so multiple users can deploy into the same VPC concurrently
  name        = "${local.key_name}_sg"
  description = "Shared security group for all EC2 instances"
  vpc_id      = local.aws_config.vpc_id

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.key_name}_sg"
  })
}

resource "aws_security_group_rule" "shared_base" {
  count             = length(local.shared_sg_rules)
  type              = "ingress"
  security_group_id = aws_security_group.shared.id
  description       = local.shared_sg_rules[count.index].description
  from_port         = local.shared_sg_rules[count.index].from_port
  to_port           = local.shared_sg_rules[count.index].to_port
  protocol          = local.shared_sg_rules[count.index].protocol
  cidr_blocks       = local.shared_sg_rules[count.index].cidr_blocks
}

# Initial rule of the security group: allow all traffic from the VPC (private)
# CIDR on all ports. This rule only applies to the internal network and is not
# mirrored for the instance public IPs (those stay port-based, see the ec2
# module's allow_vm_public_ips).
resource "aws_security_group_rule" "shared_vpc_all" {
  type              = "ingress"
  security_group_id = aws_security_group.shared.id
  description       = "All traffic from within the VPC"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = [data.aws_vpc.selected.cidr_block]
}

# Instances sharing this security group can reach each other on any port.
resource "aws_security_group_rule" "shared_self" {
  type              = "ingress"
  security_group_id = aws_security_group.shared.id
  self              = true
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  description       = "All traffic between instances in this security group"
}
