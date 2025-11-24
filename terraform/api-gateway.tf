########################################
# API Gateway - Main REST API
########################################
resource "aws_api_gateway_rest_api" "auth_api" {
  name = "auth-api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

########################################
# API Resources
########################################

# /auth
resource "aws_api_gateway_resource" "auth_resource" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  parent_id   = aws_api_gateway_rest_api.auth_api.root_resource_id
  path_part   = "auth"
}

# /auth/signup
resource "aws_api_gateway_resource" "signup_resource" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  parent_id   = aws_api_gateway_resource.auth_resource.id
  path_part   = "signup"
}

# /auth/login
resource "aws_api_gateway_resource" "login_resource" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  parent_id   = aws_api_gateway_resource.auth_resource.id
  path_part   = "login"
}

########################################
# SIGNUP POST Method + Integration
########################################
resource "aws_api_gateway_method" "signup_method" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.signup_resource.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "signup_integration" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.signup_resource.id
  http_method = aws_api_gateway_method.signup_method.http_method
  type        = "AWS_PROXY"

  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.signup_lambda.arn}/invocations"

  depends_on = [
    aws_api_gateway_method.signup_method,
    aws_lambda_function.signup_lambda
  ]
}

########################################
# LOGIN POST Method + Integration
########################################
resource "aws_api_gateway_method" "login_method" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.login_resource.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "login_integration" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.login_resource.id
  http_method = aws_api_gateway_method.login_method.http_method
  type        = "AWS_PROXY"

  uri = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.login_lambda.arn}/invocations"

  depends_on = [
    aws_api_gateway_method.login_method,
    aws_lambda_function.login_lambda
  ]
}

########################################
# CORS for POST /auth/signup (OPTIONS)
########################################
resource "aws_api_gateway_method" "signup_options" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  resource_id   = aws_api_gateway_resource.signup_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "signup_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.signup_resource.id
  http_method = aws_api_gateway_method.signup_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "signup_options_response" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.signup_resource.id
  http_method = aws_api_gateway_method.signup_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "signup_options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id
  resource_id = aws_api_gateway_resource.signup_resource.id
  http_method = aws_api_gateway_method.signup_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.signup_options_integration
  ]
}

########################################
# Deployment + Stage
########################################
resource "aws_api_gateway_deployment" "auth_deployment" {
  rest_api_id = aws_api_gateway_rest_api.auth_api.id

  depends_on = [
    aws_api_gateway_integration.signup_integration,
    aws_api_gateway_integration.login_integration
  ]
}

resource "aws_api_gateway_stage" "auth_stage" {
  rest_api_id   = aws_api_gateway_rest_api.auth_api.id
  deployment_id = aws_api_gateway_deployment.auth_deployment.id
  stage_name    = "prod"
}
