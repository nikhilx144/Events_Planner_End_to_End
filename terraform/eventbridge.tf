# terraform/eventbridge.tf

########################################
# EventBridge Rule - Daily at 8 AM UTC
########################################

resource "aws_cloudwatch_event_rule" "daily_notification_check" {
  name                = "daily-event-notification-check"
  description         = "Triggers notification Lambda daily at 8 AM UTC"
  
  # Cron expression: minute hour day month dayofweek year
  # "0 8 * * ? *" = Every day at 8:00 AM UTC
  # UTC 8 AM = 1:30 PM IST (India Standard Time)
  schedule_expression = "cron(0 8 * * ? *)"

  tags = {
    Project = var.project_name
    Service = "notifications"
  }
}

########################################
# EventBridge Target - Notification Lambda
########################################

resource "aws_cloudwatch_event_target" "notification_lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_notification_check.name
  target_id = "NotificationLambdaTarget"
  arn       = aws_lambda_function.notification_lambda.arn
}

########################################
# Lambda Permission for EventBridge
########################################

resource "aws_lambda_permission" "eventbridge_permission" {
  statement_id  = "AllowEventBridgeInvokeNotification"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notification_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_notification_check.arn
}

########################################
# Output EventBridge Rule Info
########################################

output "eventbridge_rule_name" {
  value       = aws_cloudwatch_event_rule.daily_notification_check.name
  description = "Name of EventBridge rule for daily notifications"
}

output "eventbridge_schedule" {
  value       = aws_cloudwatch_event_rule.daily_notification_check.schedule_expression
  description = "Cron schedule for notification checks"
}