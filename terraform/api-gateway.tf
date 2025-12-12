########################################
# API Gateway - Main REST API
########################################

resource "aws_api_gateway_rest_api" "auth_api" {
  name = "auth-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

########################################
# API Resources
########################################

resource "aws_api_gateway_resource" "auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  parent_id   = aws_api_gateway_rest_api.auth_api.root_resource_id
  path_part   = "auth"

  depends_on = [aws_api_gateway_rest_api.auth_api]
}

resource "aws_api_gateway_resource" "signup_resource" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  parent_id   = aws_api_gateway_resource.auth_resource.id
  path_part   = "signup"

  depends_on = [aws_api_gateway_resource.auth_resource]
}

resource "aws_api_gateway_resource" "login_resource" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  parent_id   = aws_api_gateway_resource.auth_resource.id
  path_part   = "login"

  depends_on = [aws_api_gateway_resource.auth_resource]
}

########################################
# SIGNUP POST METHOD
########################################

resource "aws_api_gateway_method" "signup_method" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.signup_resource.id
  http_method   = "POST"
  authorization = "NONE"

  depends_on = [aws_api_gateway_resource.signup_resource]
}

resource "aws_api_gateway_integration" "signup_integration" {
  rest_api_id             = aws_api_gateway_rest_api.auth_api.id
  resource_id             = aws_api_gateway_resource.signup_resource.id
  http_method             = "POST" # FIXED: Use literal string instead of reference
  type                    = "AWS_PROXY"
  integration_http_method = "POST" # ADDED: Lambda always uses POST
  uri                     = aws_lambda_function.signup_lambda.invoke_arn

  depends_on = [
    aws_api_gateway_method.signup_method,
    aws_lambda_function.signup_lambda
  ]
}

########################################
# LOGIN POST METHOD
########################################

resource "aws_api_gateway_method" "login_method" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.login_resource.id
  http_method   = "POST"
  authorization = "NONE"

  depends_on = [aws_api_gateway_resource.login_resource]
}

resource "aws_api_gateway_integration" "login_integration" {
  rest_api_id             = aws_api_gateway_rest_api.auth_api.id
  resource_id             = aws_api_gateway_resource.login_resource.id
  http_method             = "POST" # FIXED: Use literal string instead of reference
  type                    = "AWS_PROXY"
  integration_http_method = "POST" # ADDED: Lambda always uses POST
  uri                     = aws_lambda_function.login_lambda.invoke_arn

  depends_on = [
    aws_api_gateway_method.login_method,
    aws_lambda_function.login_lambda
  ]
}

########################################
# CORS for /signup OPTIONS
########################################

resource "aws_api_gateway_method" "signup_options" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.signup_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"

  depends_on = [aws_api_gateway_resource.signup_resource]
}

resource "aws_api_gateway_integration" "signup_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.signup_resource.id
  http_method = "OPTIONS" # FIXED: Use literal string
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [
    aws_api_gateway_method.signup_options
  ]
}

resource "aws_api_gateway_method_response" "signup_options_response" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.signup_resource.id
  http_method = "OPTIONS" # FIXED: Use literal string
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [
    aws_api_gateway_method.signup_options
  ]
}

resource "aws_api_gateway_integration_response" "signup_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.signup_resource.id
  http_method = "OPTIONS" # FIXED: Use literal string
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.signup_options_integration,
    aws_api_gateway_method_response.signup_options_response
  ]
}

########################################
# CORS for /login OPTIONS
########################################

resource "aws_api_gateway_method" "login_options" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.login_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"

  depends_on = [aws_api_gateway_resource.login_resource]
}

resource "aws_api_gateway_integration" "login_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.login_resource.id
  http_method = "OPTIONS"
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [
    aws_api_gateway_method.login_options
  ]
}

resource "aws_api_gateway_method_response" "login_options_response" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.login_resource.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [
    aws_api_gateway_method.login_options
  ]
}

resource "aws_api_gateway_integration_response" "login_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.login_resource.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.login_options_integration,
    aws_api_gateway_method_response.login_options_response
  ]
}

########################################
# Deployment + Stage
########################################

resource "aws_api_gateway_deployment" "auth_deployment" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id

  depends_on = [
    aws_api_gateway_integration.signup_integration,
    aws_api_gateway_integration.login_integration,
    aws_api_gateway_integration_response.signup_options_integration_response,
    aws_api_gateway_integration_response.login_options_integration_response,
    aws_api_gateway_integration.events_integration_post,
    aws_api_gateway_integration.events_integration_get,
    aws_api_gateway_integration.events_integration_put,
    aws_api_gateway_integration.events_integration_delete

  ]

  # Force new deployment on any change
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.auth_resource.id,
      aws_api_gateway_resource.signup_resource.id,
      aws_api_gateway_resource.login_resource.id,
      aws_api_gateway_method.signup_method.id,
      aws_api_gateway_method.login_method.id,
      aws_api_gateway_integration.signup_integration.id,
      aws_api_gateway_integration.login_integration.id,
      aws_api_gateway_resource.events_resource.id,
      aws_api_gateway_method.events_post.id,
      aws_api_gateway_method.events_get.id,
      aws_api_gateway_method.events_put.id,
      aws_api_gateway_method.events_delete.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "auth_stage" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  deployment_id = aws_api_gateway_deployment.auth_deployment.id
  stage_name    = "prod"

  depends_on = [aws_api_gateway_deployment.auth_deployment]
}