variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances. If not provided, latest Amazon Linux 2 AMI will be used"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair to access the instances"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where resources will be created. If not provided, default subnet will be used"
  type        = string
}

variable "security_group_id" {
  description = "ID of the shared security group that all EC2 instances attach to. The security group allows the instances to reach each other, so no per-instance rules are managed here"
  type        = string
}

variable "instance_name_prefix" {
  description = "Prefix for instance names"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the EC2 instances"
  type        = map(string)
}

variable "init_script" {
  description = "Initialize the EC2 instance."
  type        = string
  default     = ""
}

variable "root_block_device_size" {
  description = "Size of root device."
  type        = number
}

variable "iam_instance_profile" {
  description = "IAM instance profile to attach to the EC2 instances"
  type        = string
  default     = null
}