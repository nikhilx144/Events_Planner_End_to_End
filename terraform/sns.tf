# terraform/sns.tf

########################################
# SNS Topic for Event Reminders
########################################

resource "aws_sns_topic" "event_reminders" {
  name         = "event-reminders"
  display_name = "Event Planner Reminders"

  tags = {
    Project = var.project_name
    Service = "notifications"
  }
}

########################################
# SNS Email Subscription
# IMPORTANT: You need to manually confirm this email!
########################################

resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.event_reminders.arn
  protocol  = "email"
  endpoint  = var.notification_email  # Your email address

  # This will send a confirmation email
  # You MUST click the confirmation link in your email!
}

########################################
# Output SNS Topic ARN
########################################

output "sns_topic_arn" {
  value       = aws_sns_topic.event_reminders.arn
  description = "ARN of SNS topic for event reminders"
}