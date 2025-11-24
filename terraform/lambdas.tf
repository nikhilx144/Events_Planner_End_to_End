resource "aws_lambda_function" "signup_lambda" {
  function_name = "auth-signup"

  filename         = "../auth-service/signup.zip"
  handler          = "signup.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      JWT_SECRET = "mysecretkey"
    }
  }

  depends_on = [aws_iam_role_policy.lambda_policy]
}

resource "aws_lambda_function" "login_lambda" {
  function_name = "auth-login"

  filename         = "../auth-service/login.zip"
  handler          = "login.lambda_handler"
  runtime          = "python3.9"
  role             = aws_iam_role.lambda_role.arn

  environment {
    variables = {
      JWT_SECRET = "mysecretkey"
    }
  }

  depends_on = [aws_iam_role_policy.lambda_policy]
}

resource "aws_lambda_permission" "signup_permission" {
  statement_id  = "AllowAPIGatewayInvokeSignup"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.signup_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}

resource "aws_lambda_permission" "login_permission" {
  statement_id  = "AllowAPIGatewayInvokeLogin"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login_lambda.function_name
  principal     = "apigateway.amazonaws.com"
}
