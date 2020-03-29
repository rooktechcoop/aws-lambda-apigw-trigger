output "aws_api_gateway_resource_id" {
  description = "The id of the api gateway resource"
  value       = concat(aws_api_gateway_resource.api_gateway_resource.*.id, [""])[0]
}

output "aws_api_gateway_resource_path" {
  description = "The id of the api gateway resource"
  value       = concat(aws_api_gateway_resource.api_gateway_resource.*.path, [""])[0]
}

output "module_complete" {
  value = "${var.module_dependency}${var.module_dependency == "" ? "" : "->"}(${null_resource.module_is_complete.id})"
}