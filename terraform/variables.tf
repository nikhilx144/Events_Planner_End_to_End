# terraform/variables.tf

variable "project_name" {
    description = "Project name used for resource naming"
    default     = "events-planner-end-to-end"
}

variable "region" {
    description = "AWS region for resources"
    default     = "ap-south-1"
}

variable "notification_email" {
    description = "Email address to receive event notifications"
    type        = string
    # Default to empty string - you MUST set this!
    default     = ""
}

# You can set this via:
# 1. Command line: terraform apply -var="notification_email=your@email.com"
# 2. Environment variable: export TF_VAR_notification_email="your@email.com"
# 3. terraform.tfvars file (create this file and add: notification_email = "your@email.com")