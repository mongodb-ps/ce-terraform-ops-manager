# Calculate expiration date (3 days from now) if not provided
locals {
  expire_on_date = lookup(var.tags, "expire-on", "") != "" ? var.tags["expire-on"] : formatdate("YYYY-MM-DD", timeadd(timestamp(), "72h"))
}

# EC2 Instances
resource "aws_instance" "vm" {
  count                  = var.instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name != "" ? var.key_name : null
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.security_group_id]
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
