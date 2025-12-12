output "auth_api_url" {
  value = "https://${aws_api_gateway_rest_api.auth_api.id}.execute-api.${var.region}.amazonaws.com/prod/auth/"
}

output "api_base_url" {
  value = "${aws_api_gateway_deployment.auth_deployment.invoke_url}auth"
}

output "events_base_url" {
  value = "${aws_api_gateway_deployment.auth_deployment.invoke_url}events"
}
