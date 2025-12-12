########################################
# Events Service: DynamoDB, Lambda, API
########################################

# DynamoDB table for events
resource "aws_dynamodb_table" "events_table" {
  name         = "EventsTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"
  range_key    = "eventId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "eventId"
    type = "S"
  }

  tags = {
    Project = "events-planner-end-to-end"
  }
}

# IAM policy for lambda to access DynamoDB + logs
data "aws_iam_policy_document" "events_lambda_policy_doc" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      aws_dynamodb_table.events_table.arn,
      "${aws_dynamodb_table.events_table.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "events_lambda_policy" {
  name   = "events-lambda-policy"
  role   = aws_iam_role.lambda_role.name
  policy = data.aws_iam_policy_document.events_lambda_policy_doc.json
}

# Single Events Lambda function
resource "aws_lambda_function" "events_lambda" {
  function_name = "events-service"

  filename = "../event-service/events.zip" # path from terraform dir -> adjust if needed
  handler  = "events.lambda_handler"
  runtime  = "python3.9"
  role     = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      JWT_SECRET   = "mysecretkey" # replace with secure secret / use var
      EVENTS_TABLE = aws_dynamodb_table.events_table.name
    }
  }

  depends_on = [aws_iam_role_policy.lambda_policy, aws_iam_role_policy.events_lambda_policy]
}

resource "aws_lambda_permission" "events_permission" {
  statement_id  = "AllowAPIGatewayInvokeEvents"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.events_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

########################################
# API Gateway resources and methods
# (creates /events with POST/GET/PUT/DELETE)
########################################

# create a child resource /events under your existing rest api
resource "aws_api_gateway_resource" "events_resource" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  parent_id   = aws_api_gateway_rest_api.auth_api.root_resource_id
  path_part   = "events"
}

# Methods
resource "aws_api_gateway_method" "events_post" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.events_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "events_get" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.events_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "events_put" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.events_resource.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "events_delete" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.events_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
}

# Integration (AWS_PROXY) for each method — point to the single lambda
resource "aws_api_gateway_integration" "events_integration_post" {
  rest_api_id             = aws_api_gateway_rest_api.auth_api.id
  resource_id             = aws_api_gateway_resource.events_resource.id
  http_method             = aws_api_gateway_method.events_post.http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.events_lambda.invoke_arn
  integration_http_method = "POST"
  depends_on              = [aws_lambda_permission.events_permission]
}

resource "aws_api_gateway_integration" "events_integration_get" {
  rest_api_id             = aws_api_gateway_rest_api.auth_api.id
  resource_id             = aws_api_gateway_resource.events_resource.id
  http_method             = aws_api_gateway_method.events_get.http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.events_lambda.invoke_arn
  integration_http_method = "POST"
  depends_on              = [aws_lambda_permission.events_permission]
}

resource "aws_api_gateway_integration" "events_integration_put" {
  rest_api_id             = aws_api_gateway_rest_api.auth_api.id
  resource_id             = aws_api_gateway_resource.events_resource.id
  http_method             = aws_api_gateway_method.events_put.http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.events_lambda.invoke_arn
  integration_http_method = "POST"
  depends_on              = [aws_lambda_permission.events_permission]
}

resource "aws_api_gateway_integration" "events_integration_delete" {
  rest_api_id             = aws_api_gateway_rest_api.auth_api.id
  resource_id             = aws_api_gateway_resource.events_resource.id
  http_method             = aws_api_gateway_method.events_delete.http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.events_lambda.invoke_arn
  integration_http_method = "POST"
  depends_on              = [aws_lambda_permission.events_permission]
}

# Allow OPTIONS/CORS on /events (mock)
resource "aws_api_gateway_method" "events_options" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.events_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "events_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.events_resource.id
  http_method = aws_api_gateway_method.events_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "events_options_response" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.events_resource.id
  http_method = aws_api_gateway_method.events_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "events_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.events_resource.id
  http_method = aws_api_gateway_method.events_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST,PUT,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.events_options_integration]
}