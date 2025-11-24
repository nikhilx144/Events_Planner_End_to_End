resource "time_sleep" "wait_for_gateway" {
    create_duration = "5s"

    depends_on = [
        aws_api_gateway_method.signup_method,
        aws_api_gateway_method.login_method,
    ]
}
