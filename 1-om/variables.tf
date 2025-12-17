variable "aws_config" {
  description = "Configuration options for AWS."
  type = object({
    region    = string # AWS region
    vpc_id    = string # vpc_id where EC2 instances will be created. Must choose existing VPC.
    subnet_id = string # subnet_id where EC2 instances will be created. Must choose existing subnet within the VPC.
    key_name  = string # Name of the existing AWS key pair to use for EC2 instances.
  })
}
variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    "owner" : "Joe Doe",      # replace with your email address
    "expire-on" : "",         # leave empty for 3 days from creation
    "project-id" : "internal" # replace with your project id in the format PS-xxxxxx
  }
}

variable "om_config" {
  description = "Configuration options for Ops Manager."
  type = object({
    ami_id         = string # EC2 AMI ID for the Ops Manager application servers
    download_url   = string # Download URL for the Ops Manager package
    tier           = string # EC2 instance type for the Ops Manager application servers
    root_size_gb   = number # Root volume size in GB for the Ops Manager application servers
    instance_count = number # Number of Ops Manager application server instances
    backup_type    = string # Type of backup store to configure in Ops Manager. Options are 's3', 'mongo', 'fileSystem' or 'none'.
    appdb = object({
      ami_id       = string # EC2 AMI ID for the Ops Manager application DB
      tier         = string # EC2 instance type for the Ops Manager application DB
      version      = string # MongoDB version for the Ops Manager application DB. Only need major.minor version, e.g. "8.0"
      root_size_gb = number # Root volume size in GB for the Ops Manager application DB
    })
    backing_db = object({
      ami_id         = string # EC2 AMI ID for the Ops Manager backing DB
      version        = string # MongoDB version for the Ops Manager backing DB. Full version string, e.g. "8.0.16-ent"
      tier           = string # EC2 instance type for the Ops Manager backing DB
      root_size_gb   = number # Root volume size in GB for the Ops Manager backing DB
      instance_count = number # Number of instances for the Ops Manager backing DB replica set
    })
  })
  default = {
    download_url   = "https://downloads.mongodb.com/on-prem-mms/deb/mongodb-mms-8.0.16.500.20251105T1415Z.amd64.deb"
    ami_id         = null # if null, default_ami_id will be used
    tier           = "t3.xlarge"
    root_size_gb   = 50
    instance_count = 1
    appdb = {
      ami_id       = null # if null, default_ami_id will be used
      tier         = "t3.medium"
      version      = "8.0"
      root_size_gb = 50
    }
    backing_db = {
      ami_id         = null # if null, default_ami_id will be used
      version        = "8.0.16-ent"
      tier           = "t3.small"
      root_size_gb   = 50
      instance_count = 1
    }
  }
}

variable "test_instance_config" {
  description = "Configuration options for test instances."
  type = object({
    ami_id         = string # EC2 AMI ID for the test instances
    tier           = string # EC2 instance type for the test instances
    root_size_gb   = number # Root volume size in GB for the test instances
    instance_count = number # Number of test instances
  })
  default = {
    ami_id         = null
    tier           = "t3.small"
    root_size_gb   = 20
    instance_count = 1
  }
}

variable "default_ami_id" {
  description = "AMI ID for the EC2 instances."
  type        = string
  default     = "ami-01fd6fa49060e89a6" # Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
}

variable "s3_config" {
  description = "Configuration options for S3."
  type = object({
    prefix   = string
    endpoint = string
  })
  default = {
    prefix   = null # will use owner name if null
    endpoint = null # will generate AWS S3 endpoint based on your aws region if null
  }
}

variable "backing_db_credentials" {
  description = "Ops Manager user credentials"
  sensitive   = true
  type = object({
    name = string # Username for the Ops Manager backing databases user. AppDB, Oplog store, etc.
    pwd  = string # Password for the Ops Manager backing databases user. AppDB, Oplog store, etc.
  })
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
