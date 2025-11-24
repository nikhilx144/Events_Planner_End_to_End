output "auth_api_url" {
    value = "https://${aws_api_gateway_rest_api.auth_api.id}.execute-api.${var.region}.amazonaws.com/prod/auth/"
}
