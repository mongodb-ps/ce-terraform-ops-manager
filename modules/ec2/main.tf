# Get VPC information to retrieve CIDR block
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Calculate expiration date (3 days from now) if not provided
locals {
  expire_on_date = lookup(var.tags, "expire-on", "") != "" ? var.tags["expire-on"] : formatdate("YYYY-MM-DD", timeadd(timestamp(), "72h"))
  ingress_rules = concat([
    {
      description = "SSH access"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTP access"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS access"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS access"
      from_port   = 27017
      to_port     = 27017
      protocol    = "tcp"
      cidr_blocks = [data.aws_vpc.selected.cidr_block]
    }
  ], var.ingress_rules)
}

# Security Group for EC2 instances
resource "aws_security_group" "vm_sg" {
  name        = "${var.instance_name_prefix}-sg"
  description = "Security group for ${var.instance_name_prefix} EC2 instances"
  vpc_id      = var.vpc_id

  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  # All outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name_prefix}-sg"
  }
}

# EC2 Instances
resource "aws_instance" "vm" {
  count                  = var.instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name != "" ? var.key_name : null
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.vm_sg.id]
  iam_instance_profile   = var.iam_instance_profile

  # User data script for initialization
  user_data                   = var.init_script != "" ? var.init_script : null
  user_data_replace_on_change = true

  tags = merge(var.tags, {
    Name        = "${var.instance_name_prefix}-${count.index + 1}",
    "expire-on" = local.expire_on_date
  })
  volume_tags = merge(var.tags, {
    Name        = "${var.instance_name_prefix}-${count.index + 1}-root-volume",
    "expire-on" = local.expire_on_date
  })

  root_block_device {
    volume_size           = var.root_block_device_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }
}
