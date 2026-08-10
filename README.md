# Terraform Ops Manager
## 0 Disclaimer
These code samples are provided for educational and illustrative purposes only, to demonstrate the functionality of specific MongoDB features. They are not production-ready and may lack the security hardening, error handling, and testing required for a live environment.

You are responsible for testing, validating, and securing this code within your own environment before implementation. This material is provided "as is" without warranty or liability.’

## 1 What's Inside
The tool will create Ops Manager on AWS that has the following features:
- An Ops Manager instance
- A standalone AppDB
- A database for backup which has configurable number of members.
- Some EC2 instances that has automation running and pointing to "TestProject". You can use these instances to build your cluster for testing.
- One of the backup solutions configured:
  - S3
  - Oplog store + Blockstore (Both using the same DB)
  - Oplog store + FileSystem store

## 2 Structure of Repo
The main folders that you need to use are:
- `1-om`: Terraform scripts that create:
  - Ops Manager application
  - AppDB
- `2-clusters`: Terraform scripts that creates:
  - Test instances
  - Backup database (Oplog/Block store, S3 metadata store)
  - S3 buckets for backup (Oplog/Snapshot)

Due to the limitation of Terraform, I can't do everything in 1 phase. You need to finish `1-om` then start `2-clusters`.

## 3 Use the Tool
### 3.1 Variables
Everything is autowired: only `aws_config.region` is required, every other variable has a default or is derived automatically. The variables below let you customize the deployment. You can find in `1-om/variables.tf` all the other variables and instructions.

#### aws_config
| Field        | Required | Description                                                                                                                                                                                                               |
| ------------ | -------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `region`     | Yes      | AWS region that you want to create the environment.                                                                                                                                                                       |
| `vpc_id`     | No       | The VPC ID that you want to host the environment. Leave empty to let Terraform create a VPC with a public subnet automatically. If provided, the VPC must exist and can assign public IP addresses for the EC2 instances. |
| `subnet_id`  | No       | The subnet where you want to create the EC2 instances. Leave empty to let Terraform create a public subnet automatically. Must be provided together with `vpc_id`.                                                        |
| `key_name`   | No       | The AWS key pair that will be assigned to all the EC2 instances. When not provided, the local part of `email` (before `@`) is used. The local key pair must exist at `~/.ssh/<key_name>` and `~/.ssh/<key_name>.pub`, otherwise the plan fails. Terraform creates the key pair on AWS; if it already exists but is not in the Terraform state, import it once with `terraform import aws_key_pair.vm <key_name>`. |

#### email
| Field   | Required | Description                                                                                                                                                                                                |
| ------- | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `email` | No       | Your email. It fills `tags.owner` and the first Ops Manager user's email. When not provided, it is derived from the ARN of your AWS identity (same value as `aws sts get-caller-identity`).                |

> **Note:** the ARN must contain a user name (e.g. `arn:aws:iam::123456789012:user/joe@example.com`) for the email to be derived. When the ARN has no user part (e.g. an account root `arn:aws:iam::123456789012:root`), set `email` explicitly or the plan will fail.

#### tags
| Field        | Required | Description                                                                                                                       |
| ------------ | -------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `owner`      | No       | Filled from the `email` variable.                                                                                                 |
| `expire-on`  | No       | Use empty string auto fill a date that represents 3 days later. Otherwise please fill in the format of: `yyyy-MM-dd`.             |
| `project-id` | No       | Defaults to `internal`. You have responsibility to fill the real PS project ID from Salesforce. The format is: `PS-<project ID>`. |

#### backing_db_credentials
| Field  | Required | Description                                                                                                                                               |
| ------ | -------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name` | No       | Username for the backing databases (AppDB, Oplog/Block store, and S3 metadata store). When not provided, `root` is used.                                    |
| `pwd`  | No       | Password for the user above. When not provided, a random alphanumeric password is generated.                                                              |

#### first_user
The first Ops Manager user. This will be the Ops Manager admin.

| Field       | Required | Description                                                                                                                            |
| ----------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `email`     | No       | Email of the user. When not provided, filled from the `email` variable.                                                                |
| `pwd`       | No       | Password of the user. When not provided, a random one (8+ characters with upper/lowercase letters, digits and special characters) is generated. |
| `firstName` | No       | First name of the user. When not provided, derived from the local part of `email`: the part before the first `.`, or the whole local part when there is no `.`. |
| `lastName`  | No       | Last name of the user. When not provided, derived from the local part of `email`: the part after the first `.`, or `Doe` when there is no `.`.                 |

### 3.2 Deploy Ops Manager
#### AWS Credentials
- Open AWS from company portal.
- Click "Access keys"
- Copy credential from "Option 1: Set AWS environment variables"
- Paste into bash

#### Execute Script
Create Ops Manager:
```bash
git clone https://github.com/zhangyaoxing/terraform-ops-manager
cd 1-om
terraform init
terraform apply
```
Create the rest:
```bash
cd 2-clusters
terraform init
terraform apply
```
Destroy the environment:
```bash
cd 2-clusters
terraform destroy
cd ../1-om
terraform destroy
```

## 4 Known Issues
### 4.1 Ops Manager API
There's no Terraform provider for Ops Manager. So I have to create some Python scripts to call the API, and use the `null_resource` to call the Python scripts. In this case, the resources (Orgs, Projects, Clusters) in Ops Manager will not be properly destroyed. This is usually harmless because they will be destroyed when you destroy Ops Manager.

### 4.2 Standalone AppDB
Although you can customize how many instances of backup DB, test DB you need, the AppDB currenly only support a single instance standalone. This should be enough for most use cases.

### 4.3 Certificates
Features that needs certificates are not supported at the moment. Including:
- HTTPS
- Queryable backup

### 4.4 Email
SMTP is not configured at the moment. All features that rely on the email will fail.