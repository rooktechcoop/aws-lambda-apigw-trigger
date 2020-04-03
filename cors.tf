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

## adding CORs support ## It's only one for resource

resource "aws_api_gateway_method" "cors_method" {
  count = var.cors_enable ? 1 : 0
  depends_on = [null_resource.module_dependency]

  rest_api_id   = var.api_gateway_id
  resource_id   = var.api_gateway_resource_id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# aws_api_gateway_integration.
resource "aws_api_gateway_integration" "cors_integration" {
  count = var.cors_enable ? 1 : 0
  depends_on = [null_resource.module_dependency]

  rest_api_id = var.api_gateway_id
  resource_id = var.api_gateway_resource_id
  http_method = aws_api_gateway_method.cors_method[0].http_method

  type = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }
}

# aws_api_gateway_integration_response._
resource "aws_api_gateway_integration_response" "cors_response" {
  count = var.cors_enable ? 1 : 0
  depends_on = [null_resource.module_dependency, aws_api_gateway_integration.cors_integration, aws_api_gateway_method_response.cors_method_response]

  rest_api_id = var.api_gateway_id
  resource_id = var.api_gateway_resource_id
  http_method = aws_api_gateway_method.cors_method[0].http_method
  status_code = 200

  response_parameters = local.integration_response_parameters

}

# aws_api_gateway_method_response._
resource "aws_api_gateway_method_response" "cors_method_response" {
  count = var.cors_enable ? 1 : 0
  depends_on = [null_resource.module_dependency, aws_api_gateway_method.cors_method]

  rest_api_id = var.api_gateway_id
  resource_id = var.api_gateway_resource_id
  http_method = aws_api_gateway_method.cors_method[0].http_method
  status_code = 200

  response_parameters = local.method_response_parameters

  response_models = {
    "application/json" = "Empty"
  }

}
