terraform {
  required_version = ">= 0.12.19"
}

resource "null_resource" "module_dependency" {
  triggers = {
    dependency = var.module_dependency
  }
}

## Lambda
resource "aws_lambda_permission" "lambda_permission" {
  count = var.enable_lambda_permission ? 1 : 0
  depends_on = [null_resource.module_dependency]

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${var.api_gateway_id}/*/${var.request_method}${var.api_gateway_resource_path}"
}


resource "aws_api_gateway_method" "api_gateway_method" {
  depends_on = [null_resource.module_dependency]

  rest_api_id   = var.api_gateway_id
  resource_id   = var.api_gateway_resource_id
  http_method   = var.request_method
  authorization = length(var.authorizer_id) > 0 ? var.authorizer_type : "NONE"
  authorizer_id = length(var.authorizer_id) > 0 ? var.authorizer_id : ""
}

resource "aws_api_gateway_integration" "integration" {
  depends_on = [null_resource.module_dependency, aws_api_gateway_method.api_gateway_method]

  rest_api_id             = var.api_gateway_id
  resource_id             = var.api_gateway_resource_id
  http_method             = var.request_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_uri_arn
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  depends_on = [null_resource.module_dependency,  aws_api_gateway_method.api_gateway_method, aws_api_gateway_integration.integration]

  rest_api_id = var.api_gateway_id
  stage_name  = var.stage_name
}


resource "null_resource" "module_is_complete" {
  depends_on = [aws_api_gateway_method.api_gateway_method, aws_api_gateway_deployment.api_gateway_deployment, aws_api_gateway_integration.integration]

  provisioner "local-exec" {
    command = "echo Module complete"
  }
}