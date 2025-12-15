variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "eu-north-1" # Stockholm region
}
variable "vpc_id" {
  description = "VPC ID where resources will be created. If not provided, default VPC will be used"
  type        = string
  default     = "vpc-bf7894d6" # Stockholm region default VPC
}
variable "subnet_id" {
  description = "Subnet ID where resources will be created. If not provided, default subnet will be used"
  type        = string
  default     = "subnet-7b2ac712" # Stockholm region default subnet eu-north-1a
}
variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    "owner" : "Joe Doe", # replace with your name
    "expire-on" : "",    # leave empty for 3 days from creation
    "project-id" : "internal"
  }
}
variable "backing_db_credentials" {
  description = "Ops Manager user credentials"
  sensitive   = true
  type = object({
    name = string
    pwd  = string
  })
}
variable "om_download_url" {
  description = "URL for downloading Ops Manager"
  type        = string
  default     = "https://downloads.mongodb.com/on-prem-mms/deb/mongodb-mms-8.0.16.500.20251105T1415Z.amd64.deb"
}

variable "first_user" {
  description = "First user credentials for Ops Manager"
  sensitive   = true
  type = object({
    email     = string
    pwd       = string
    firstName = string
    lastName  = string
  })
}

variable "ami_id" {
  description = "AMI ID for the EC2 instances. If not provided, latest Amazon Linux 2 AMI will be used"
  type        = string
  default     = "ami-01fd6fa49060e89a6" # Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
}

variable "key_name" {
  description = "Name of the SSH key pair to access the instances"
  type        = string
}

variable "instance_name_prefix" {
  description = "Prefix for instance names"
  type        = string
  default     = "terraform-om-ec2"
}

variable "appdb_size" {
  description = "Disk size (GB) of application database."
  type        = number
  default     = 50
}

variable "om_size" {
  description = "Disk size (GB) of Ops Manager App."
  type        = number
  default     = 50
}

variable "snapshot_size" {
  description = "Disk size (GB) of snapshot."
  type        = number
  default     = 50
}

variable "metastore_version" {
  description = "Metadata store MongoDB version."
  type        = string
  default     = "8.0.16-ent"
}

variable "appdb_tier" {
  description = "Instance type for application database."
  type        = string
  default     = "t3.medium"
}

variable "om_tier" {
  description = "Instance type for Ops Manager."
  type        = string
  default     = "t3.xlarge"
}

variable "appdb_version" {
  description = "Version of the application database."
  type        = string
  default     = "8.0" # Will always use the latest 8.0.x enterprise.
}

variable "num_test_instances" {
  description = "Number of test instances to create"
  type        = number
  default     = 3
}

variable "test_instance_tier" {
  description = "Instance tier for test instances"
  type        = string
  default     = "t3.small"
}

variable "test_instance_size" {
  description = "Disk size (GB) of test instance."
  type = number
  default = 20
}

variable "metastore_tier" {
  description = "Instance tier for metastore."
  type        = string
  default     = "t3.small"
}

variable "s3_prefix" {
  description = "Prefix of S3 buckets. Need to be globally unique."
  type        = string
}