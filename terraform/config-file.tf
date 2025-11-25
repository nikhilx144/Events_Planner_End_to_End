resource "local_file" "frontend_config" {
  content = jsonencode({
    API_BASE = "https://${aws_api_gateway_rest_api.auth_api.id}.execute-api.${var.region}.amazonaws.com/prod/auth"
  })

  filename = "${path.module}/../frontend/config.json"

  depends_on = [
    aws_api_gateway_stage.auth_stage
  ]
}
