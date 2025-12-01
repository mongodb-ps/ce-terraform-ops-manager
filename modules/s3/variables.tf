variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default     = "yaoxing-s3-bucket"
}

variable "tags" {
  description = "Additional tags to apply to the S3 bucket"
  type        = map(string)
  default = {
    "owner" : "yaoxing.zhang",
    "expire-on" : "",
    "project-id" : "internal"
  }
}
