variable "om_automation_version" {
  description = "Filename for the Ops Manager Automation Agent"
  type        = string
  default     = "108.0.16.8895-1"
}

variable "om_monitoring_version" {
  description = "Version of monitoring agent"
  type = string
  default = "7.2.0.488-1"
}

variable "om_backup_version" {
  description = "Version of backup agent."
  type = string
  default = "7.8.1.1109-1"
}