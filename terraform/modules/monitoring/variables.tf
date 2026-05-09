variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "alarm_email" {
  description = "Email for alarm notifications"
  type        = string
  default     = "charles@damolak.com"
}
