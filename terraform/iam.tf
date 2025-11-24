resource "aws_iam_role" "lambda_role" {
    name = "${var.project_name}-lambda-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
        Effect = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action = "sts:AssumeRole"
        }]
    })
}

# Allow Lambda to write logs + access DynamoDB
resource "aws_iam_role_policy" "lambda_policy" {
    name = "${var.project_name}-lambda-policy"
    role = aws_iam_role.lambda_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Effect = "Allow"
            Action = [
            "logs:*"
            ]
            Resource = "arn:aws:logs:*:*:*"
        },
        {
            Effect = "Allow"
            Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:UpdateItem"
            ]
            Resource = aws_dynamodb_table.users_table.arn
        }
        ]
    })
}
