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

variable "metastore_tier" {
  description = "Instance tier for metastore"
  type        = string
  default     = "t3.small"
}