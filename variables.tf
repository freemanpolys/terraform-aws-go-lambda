variable "project_name" {
    type = string
    description = "Project name"
}
variable "lambda_region" {
    type = string
    description = "Lambda Aws region"
}
variable "lambda_name" {
    type = string
    description = "Lambda name"
}

variable "lambda_api_http_method" {
    type = string
    description = "Lambda Gateway API method"
}
variable "go_bin_path" {
    type = string
    description = "Go binary file path"
}
variable "tags" {
  type = map(string)
  description = "Tags"
  default = {
    "CreateBy" = "Terraform"
  }
}