resource "time_sleep" "wait_for_methods" {
  depends_on = [
    aws_api_gateway_method.signup_method,
    aws_api_gateway_method.login_method
  ]

  create_duration = "60s"
}
