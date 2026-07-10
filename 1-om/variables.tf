variable "aws_config" {
  description = <<-EOT
    Configuration options for AWS.

    | Field | Description |
    | --- | --- |
    | `region` | AWS region. |
    | `vpc_id` | ID of the existing VPC where EC2 instances will be created. |
    | `subnet_id` | ID of the existing subnet within the VPC where EC2 instances will be created. |
    | `key_name` | Name of the existing AWS key pair to use for EC2 instances. |
  EOT
  type = object({
    region    = string
    vpc_id    = string
    subnet_id = string
    key_name  = string
  })
}
variable "tags" {
  description = <<-EOT
    Tags for all resources.

    | Key | Description |
    | --- | --- |
    | `owner` | Your email address. |
    | `expire-on` | Expiration date. Leave empty to use three days from creation. |
    | `project-id` | Project ID in the format `PS-xxxxxx`. |
  EOT
  type        = map(string)
  default = {
    "owner" : "Joe Doe",
    "expire-on" : "",
    "project-id" : "internal"
  }
}

variable "om_config" {
  description = <<-EOT
    Configuration options for Ops Manager.

    | Field | Description |
    | --- | --- |
    | `ami_id` | EC2 AMI ID for the Ops Manager application servers. When null, `default_ami_id` is used. |
    | `download_url` | Download URL for the Ops Manager package. |
    | `tier` | EC2 instance type for the Ops Manager application servers. |
    | `root_size_gb` | Root volume size in GB for the Ops Manager application servers. |
    | `instance_count` | Number of Ops Manager application server instances. |
    | `backup_type` | Backup store type. Valid options are `s3`, `mongo`, `fileSystem`, and `none`. |
    | `appdb.ami_id` | EC2 AMI ID for the Ops Manager application database. When null, `default_ami_id` is used. |
    | `appdb.tier` | EC2 instance type for the Ops Manager application database. |
    | `appdb.version` | MongoDB major and minor version for the Ops Manager application database, for example `8.0`. |
    | `appdb.root_size_gb` | Root volume size in GB for the Ops Manager application database. |
    | `backing_db.ami_id` | EC2 AMI ID for the Ops Manager backing database. When null, `default_ami_id` is used. |
    | `backing_db.version` | Full MongoDB version for the Ops Manager backing database, for example `8.0.16-ent`. |
    | `backing_db.tier` | EC2 instance type for the Ops Manager backing database. |
    | `backing_db.root_size_gb` | Root volume size in GB for the Ops Manager backing database. |
    | `backing_db.instance_count` | Number of instances in the Ops Manager backing database replica set. |
  EOT
  type = object({
    ami_id         = string
    download_url   = string
    tier           = string
    root_size_gb   = number
    instance_count = number
    backup_type    = string
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
    download_url   = "https://downloads.mongodb.com/on-prem-mms/deb/mongodb-mms-8.0.16.500.20251105T1415Z.amd64.deb"
    ami_id         = null
    tier           = "t3.xlarge"
    root_size_gb   = 50
    instance_count = 1
    backup_type    = "s3"
    appdb = {
      ami_id       = null
      tier         = "t3.medium"
      version      = "8.0"
      root_size_gb = 50
    }
    backing_db = {
      ami_id         = null
      version        = "8.0.16-ent"
      tier           = "t3.small"
      root_size_gb   = 50
      instance_count = 1
    }
  }
}

variable "test_instance_config" {
  description = <<-EOT
    Configuration options for test instances.

    | Field | Description |
    | --- | --- |
    | `ami_id` | EC2 AMI ID for the test instances. |
    | `tier` | EC2 instance type for the test instances. |
    | `root_size_gb` | Root volume size in GB for the test instances. |
    | `instance_count` | Number of test instances. |
  EOT
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
    instance_count = 1
  }
}

variable "default_ami_id" {
  description = "AMI ID for EC2 instances. The default is Ubuntu Server 22.04 LTS (HVM) with SSD volume type."
  type        = string
  default     = "ami-01fd6fa49060e89a6"
}

variable "s3_config" {
  description = <<-EOT
    Configuration options for S3.

    | Field | Description |
    | --- | --- |
    | `prefix` | Bucket prefix. When null, the owner name is used. |
    | `endpoint` | S3 endpoint. When null, the endpoint is generated from the configured AWS region. |
  EOT
  type = object({
    prefix   = string
    endpoint = string
  })
  default = {
    prefix   = null
    endpoint = null
  }
}

variable "backing_db_credentials" {
  description = <<-EOT
    Ops Manager backing database credentials.

    | Field | Description |
    | --- | --- |
    | `name` | Username for the Ops Manager backing databases, including the application database and oplog store. |
    | `pwd` | Password for the Ops Manager backing databases, including the application database and oplog store. |
  EOT
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
