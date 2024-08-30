output "api_gateway_url" {
  value = "${aws_api_gateway_rest_api.my_api.id}.execute-api.${var.lambda_region}.amazonaws.com"
}