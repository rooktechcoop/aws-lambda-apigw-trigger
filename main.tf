terraform {
  required_version = ">= 0.12.19"
}

locals {
  headers = "${
    map(
      "Access-Control-Allow-Headers", "'${join(",", var.allow_headers)}'",
      "Access-Control-Allow-Methods", "'${join(",", var.allow_methods)}'",
      "Access-Control-Allow-Origin", "'${var.allow_origin}'",
      "Access-Control-Max-Age", "'${var.allow_max_age}'",
      "Access-Control-Allow-Credentials", "${var.allow_credentials ? "'true'" : ""}"
    )
  }"

  # Pick non-empty header values
  header_values = "${compact(values(local.headers))}"

  # Pick names that from non-empty header values
  header_names = "${matchkeys(
    keys(local.headers),
    values(local.headers),
    local.header_values
  )}"

  # Parameter names for method and integration responses
  parameter_names = "${
    formatlist("method.response.header.%s", local.header_names)
  }"

  # Map parameter list to "true" values
  true_list = "${
    split("|", replace(join("|", local.parameter_names), "/[^|]+/", "true"))
  }"

  # Integration response parameters
  integration_response_parameters = "${zipmap(
    local.parameter_names,
    local.header_values
  )}"

  # Method response parameters
  method_response_parameters = "${zipmap(
    local.parameter_names,
    local.true_list
  )}"
}


## Lambda
resource "aws_lambda_permission" "lambda_permission" {

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.api_gateway_id}/*/${var.request_method}${length(var.api_gateway_resource_path) == 0 ? aws_api_gateway_resource.api_gateway_resource[0].path : var.api_gateway_resource_path}"
}


resource "aws_api_gateway_resource" "api_gateway_resource" {
  count =  length(var.api_gateway_resource_id) > 0 ? 1 : 0

  rest_api_id = var.api_gateway_id
  parent_id   = var.api_gateway_root_resource_id
  path_part   = var.resource_path
}

locals {
  reource_id = length(var.api_gateway_resource_id) == 0 ? aws_api_gateway_resource.api_gateway_resource[0].id : var.api_gateway_resource_id
}


resource "aws_api_gateway_method" "api_gateway_method" {

  rest_api_id   = var.api_gateway_id
  resource_id   = local.reource_id
  http_method   = var.request_method
  authorization = length(var.authorizer_id) > 0 ? var.authorizer_type : "NONE"
  authorizer_id = length(var.authorizer_id) > 0 ? var.authorizer_id : ""
}

resource "aws_api_gateway_integration" "integration" {

  rest_api_id             = var.api_gateway_id
  resource_id             = local.reource_id
  http_method             = var.request_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  depends_on = [aws_api_gateway_integration.integration]

  rest_api_id = var.api_gateway_id
  stage_name  = var.stage_name
}


## adding CORs support ##

resource "aws_api_gateway_method" "cors_method" {
  count = var.cors_enable && length(var.api_gateway_resource_id) == 0 ? 1 : 0

  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.api_gateway_resource[0].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# aws_api_gateway_integration.
resource "aws_api_gateway_integration" "cors_integration" {
  count = var.cors_enable && length(var.api_gateway_resource_id) == 0 ? 1 : 0

  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.api_gateway_resource[0].id
  http_method = aws_api_gateway_method.cors_method[0].http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

# aws_api_gateway_integration_response._
resource "aws_api_gateway_integration_response" "cors_response" {
  count = var.cors_enable && length(var.api_gateway_resource_id) == 0 ? 1 : 0

  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.api_gateway_resource[0].id
  http_method = aws_api_gateway_method.cors_method[0].http_method
  status_code = 200

  response_parameters = local.integration_response_parameters

  depends_on = [aws_api_gateway_integration.cors_integration, aws_api_gateway_method_response.cors_method_response]
}

# aws_api_gateway_method_response._
resource "aws_api_gateway_method_response" "cors_method_response" {
  count = var.cors_enable && length(var.api_gateway_resource_id) == 0 ? 1 : 0

  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.api_gateway_resource[0].id
  http_method = aws_api_gateway_method.cors_method[0].http_method
  status_code = 200

  response_parameters = local.method_response_parameters

  response_models = {
    "application/json" = "Empty"
  }

  depends_on = [aws_api_gateway_method.cors_method]
}
