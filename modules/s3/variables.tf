variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the S3 bucket"
  type        = map(string)
}
