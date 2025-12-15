variable "aws_config" {
  description = "Configuration options for AWS."
  type = object({
    region    = string
    vpc_id    = string
    subnet_id = string
    key_name  = string
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
    ami_id       = string
    download_url = string
    tier         = string
    root_size_gb = number
    appdb = object({
      ami_id       = string
      tier         = string
      version      = string
      root_size_gb = number
    })
    backing_db = object({
      ami_id         = string
      version        = string
      tier           = string
      root_size_gb   = number
      instance_count = number
    })
  })
  default = {
    download_url = "https://downloads.mongodb.com/on-prem-mms/deb/mongodb-mms-8.0.16.500.20251105T1415Z.amd64.deb"
    ami_id       = null # if null, default_ami_id will be used
    tier         = "t3.xlarge"
    root_size_gb = 50
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
      instance_count = 3
    }
  }
}

variable "test_instance_config" {
  description = "Configuration options for test instances."
  type = object({
    ami_id         = string
    tier           = string
    root_size_gb   = number
    instance_count = number
  })
  default = {
    ami_id         = null
    tier           = "t3.small"
    root_size_gb   = 20
    instance_count = 3
  }
}

variable "default_ami_id" {
  description = "AMI ID for the EC2 instances."
  type        = string
  default     = "ami-01fd6fa49060e89a6" # Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
}

variable "s3_prefix" {
  description = "Prefix of S3 buckets. Need to be globally unique."
  type        = string
  default     = null # if null, your username will be used
}

variable "backing_db_credentials" {
  description = "Ops Manager user credentials"
  sensitive   = true
  type = object({
    name = string
    pwd  = string
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
