output "module_complete" {
  value = "${var.module_dependency}${var.module_dependency == "" ? "" : "->"}(${null_resource.module_is_complete.id})"
}