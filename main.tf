provider "aws" {
  region = var.lambda_region
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = var.go_bin_path
  output_path = "${var.go_bin_path}.zip"
}


resource "aws_lambda_function" "my_lambda_function" {
  filename         = "${var.go_bin_path}.zip"
  function_name    = "main"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "main"
  runtime          = "go1.x"
  source_code_hash = data.archive_file.lambda.output_base64sha256
  tags = merge(tomap({
     "Name" =   "api_${var.lambda_name}",
     "Project" = var.project_name
     "CreateBy" = "Terraform"
   }), var.tags)
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.lambda_name}-lambda-exec-role"
  tags = merge(tomap({
     "Name" =   "api-${var.lambda_name}",
     "Project" = var.project_name
     "CreateBy" = "Terraform"
   }), var.tags)
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "lambda_policy_attach" {
  name       = "${var.lambda_name}-lambda-policy-attachment"
  roles      = [aws_iam_role.lambda_exec_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_api_gateway_rest_api" "my_api" {
  name        = "api-${var.lambda_name}"
  tags = merge(tomap({
     "Name" =   "api_${var.lambda_name}",
     "Project" = var.project_name
     "CreateBy" = "Terraform"
   }), var.tags)
}

resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.my_api.id
  parent_id   = aws_api_gateway_rest_api.my_api.root_resource_id
  path_part   = "resource-${var.lambda_name}"
}

resource "aws_api_gateway_method" "my_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api.id
  resource_id   = aws_api_gateway_resource.root.id
  http_method   = var.lambda_api_http_method
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "my_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api.id
  resource_id             = aws_api_gateway_resource.root.id
  http_method             = aws_api_gateway_method.my_method.http_method
  integration_http_method = var.lambda_api_http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.my_api.execution_arn}/*/*"
}

