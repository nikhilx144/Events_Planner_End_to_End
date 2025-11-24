########################################
# Delay AFTER methods, BEFORE integrations
########################################

resource "time_sleep" "wait_for_methods" {
  depends_on = [
    aws_api_gateway_method.signup_method,
    aws_api_gateway_method.login_method,
    aws_api_gateway_method.signup_options
  ]

  create_duration = "10s"
}

########################################
# Delay AFTER REST API, BEFORE resources
########################################

resource "time_sleep" "wait_for_rest_api" {
  depends_on = [
    aws_api_gateway_rest_api.auth_api
  ]

  create_duration = "20s"
}
