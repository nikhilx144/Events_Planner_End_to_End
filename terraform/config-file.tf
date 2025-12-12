resource "local_file" "frontend_config" {
  filename = "${path.module}/../frontend/config.json"

  content = jsonencode({
    auth_base   = "https://${aws_api_gateway_rest_api.auth_api.id}.execute-api.${var.region}.amazonaws.com/prod/auth"
    events_base = "https://${aws_api_gateway_rest_api.auth_api.id}.execute-api.${var.region}.amazonaws.com/prod/events"
  })

  depends_on = [
    aws_api_gateway_stage.auth_stage
  ]
}
