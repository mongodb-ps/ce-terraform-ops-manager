variable "aws_config" {
  description = <<-EOT
    Configuration options for AWS.

    | Field       | Description                                                                                    |
    | ----------- | ---------------------------------------------------------------------------------------------- |
    | `region`    | AWS region.                                                                                    |
    | `vpc_id`    | ID of the existing VPC where EC2 instances will be created. When null, a VPC is created.       |
    | `subnet_id` | ID of the existing subnet where EC2 instances will be created. When null, a subnet is created. |
    | `key_name`  | Name of the AWS key pair. When null, the local part of the `email` (before `@`) is used. When the local key pair does not exist at `~/.ssh/<key_name>` and `~/.ssh/<key_name>.pub`, Terraform generates a new one, imports it into AWS and saves the private key to `~/.ssh/<key_name>`. If the key pair already exists on AWS but is not in the Terraform state, import it once with `terraform import aws_key_pair.vm <key_name>`. |
  EOT
  type = object({
    region    = string
    vpc_id    = optional(string)
    subnet_id = optional(string)
    key_name  = optional(string)
  })
  validation {
    condition     = (var.aws_config.vpc_id != null && var.aws_config.subnet_id != null) || (var.aws_config.vpc_id == null && var.aws_config.subnet_id == null)
    error_message = "vpc_id and subnet_id must either both be provided (existing VPC) or both be omitted (a VPC and subnet are created automatically)."
  }
}
variable "email" {
  description = <<-EOT
    Email address used to fill `tags.owner` and the email of the first Ops Manager user.

    When not provided, the email is derived from the ARN of the AWS identity running Terraform
    (the same value returned by `aws sts get-caller-identity`), for example
    `arn:aws:iam::123456789012:user/joe@example.com`.
  EOT
  type        = string
  default     = null
}

variable "tags" {
  description = <<-EOT
    Tags for all resources.

    | Key          | Description                                                   |
    | ------------ | ------------------------------------------------------------- |
    | `owner`      | Filled from the `email` variable.                             |
    | `expire-on`  | Expiration date. Leave empty to use three days from creation. |
    | `project-id` | Project ID in the format `PS-xxxxxx`.                         |
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

    | Field                       | Description                                                                                  |
    | --------------------------- | -------------------------------------------------------------------------------------------- |
    | `ami_id`                    | EC2 AMI ID for the Ops Manager application servers. When null, `default_ami_id` is used.     |
    | `version`                   | Ops Manager version, for example `8.0.16`. The download URL is resolved from the Ops Manager release archive: the newest package whose name contains `version`. When null, the newest available package is used. |
    | `tier`                      | EC2 instance type for the Ops Manager application servers.                                   |
    | `root_size_gb`              | Root volume size in GB for the Ops Manager application servers.                              |
    | `instance_count`            | Number of Ops Manager application server instances.                                          |
    | `backup_type`               | Backup store type. Valid options are `s3`, `mongo`, `fileSystem`, and `none`.                |
    | `appdb.ami_id`              | EC2 AMI ID for the Ops Manager application database. When null, `default_ami_id` is used.    |
    | `appdb.tier`                | EC2 instance type for the Ops Manager application database.                                  |
    | `appdb.version`             | MongoDB major and minor version for the Ops Manager application database, for example `8.0`. |
    | `appdb.root_size_gb`        | Root volume size in GB for the Ops Manager application database.                             |
    | `backing_db.ami_id`         | EC2 AMI ID for the Ops Manager backing database. When null, `default_ami_id` is used.        |
    | `backing_db.version`        | Full MongoDB version for the Ops Manager backing database, for example `8.0.16-ent`.         |
    | `backing_db.tier`           | EC2 instance type for the Ops Manager backing database.                                      |
    | `backing_db.root_size_gb`   | Root volume size in GB for the Ops Manager backing database.                                 |
    | `backing_db.instance_count` | Number of instances in the Ops Manager backing database replica set.                         |
  EOT
  type = object({
    ami_id         = string
    version        = optional(string)
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

    | Field            | Description                                    |
    | ---------------- | ---------------------------------------------- |
    | `ami_id`         | EC2 AMI ID for the test instances.             |
    | `tier`           | EC2 instance type for the test instances.      |
    | `root_size_gb`   | Root volume size in GB for the test instances. |
    | `instance_count` | Number of test instances.                      |
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

    | Field      | Description                                                                       |
    | ---------- | --------------------------------------------------------------------------------- |
    | `prefix`   | Bucket prefix. When null, the owner name is used.                                 |
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
    Credentials for the Ops Manager backing databases, including the application database and oplog store.

    | Field  | Description                                                                                        |
    | ------ | -------------------------------------------------------------------------------------------------- |
    | `name` | Username for the Ops Manager backing databases. When not provided, `root` is used.                 |
    | `pwd`  | Password for the Ops Manager backing databases. When not provided, a random one is generated.      |
  EOT
  sensitive   = true
  type = object({
    name = optional(string)
    pwd  = optional(string)
  })
  default = {}
}

variable "first_user" {
  description = <<-EOT
    Credentials for the first Ops Manager user, who will be the Ops Manager admin.

    | Field       | Description                                                                                                                                                          |
    | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
    | `email`     | Email of the user. When not provided, filled from the `email` variable.                                                                                              |
    | `pwd`       | Password of the user. When not provided, a random one (8+ characters with upper/lowercase letters, digits and special characters) is generated.                      |
    | `firstName` | First name of the user. When not provided, derived from the local part of `email`: the part before the first `.`, or the whole local part when there is no `.`.      |
    | `lastName`  | Last name of the user. When not provided, derived from the local part of `email`: the part after the first `.`, or `Doe` when there is no `.`.                       |
  EOT
  sensitive   = true
  type = object({
    email     = optional(string)
    pwd       = optional(string)
    firstName = optional(string)
    lastName  = optional(string)
  })
  default = {}
}
