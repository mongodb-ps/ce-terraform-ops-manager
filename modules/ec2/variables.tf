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

variable "vpc_id" {
  description = "VPC ID where resources will be created. If not provided, default VPC will be used"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where resources will be created. If not provided, default subnet will be used"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH into the instances"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
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
