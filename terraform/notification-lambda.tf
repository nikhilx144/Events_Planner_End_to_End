# terraform/notification-lambda.tf

########################################
# Notification Lambda Function
########################################

resource "aws_lambda_function" "notification_lambda" {
  function_name = "event-notification-service"
  filename      = "../notify-service/notification.zip"
  handler       = "notification.lambda_handler"
  runtime       = "python3.9"
  role          = aws_iam_role.notification_lambda_role.arn
  timeout       = 30  # Longer timeout for processing multiple events
  memory_size   = 256

  environment {
    variables = {
      EVENTS_TABLE  = aws_dynamodb_table.events_table.name
      USERS_TABLE   = aws_dynamodb_table.users_table.name
      SNS_TOPIC_ARN = aws_sns_topic.event_reminders.arn
    }
  }

  depends_on = [
    aws_iam_role_policy.notification_lambda_policy,
    aws_dynamodb_table.events_table,
    aws_dynamodb_table.users_table,
    aws_sns_topic.event_reminders
  ]

  tags = {
    Project = var.project_name
    Service = "notifications"
  }
}

########################################
# IAM Role for Notification Lambda
########################################

resource "aws_iam_role" "notification_lambda_role" {
  name = "${var.project_name}-notification-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Project = var.project_name
    Service = "notifications"
  }
}

########################################
# IAM Policy for Notification Lambda
########################################

resource "aws_iam_role_policy" "notification_lambda_policy" {
  name = "${var.project_name}-notification-lambda-policy"
  role = aws_iam_role.notification_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      # DynamoDB - Read Events and Users
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:GetItem"
        ]
        Resource = [
          aws_dynamodb_table.events_table.arn,
          "${aws_dynamodb_table.events_table.arn}/index/*",
          aws_dynamodb_table.users_table.arn
        ]
      },
      # SNS - Publish Messages
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.event_reminders.arn
      }
    ]
  })
}