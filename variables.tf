variable "lambda_function_name" {
  description = "The name of lambda"
}

variable "lambda_invoke_uri_arn" {
  description = "The lambda invoke uri arn"
}

variable "api_gateway_id" {
  description = "The id of the api gateway resource"
  default     = ""
}

variable "api_gateway_root_resource_id" {
  description = "The parent resource id of the api gateway"
  default     = ""
}

variable "resource_path" {
  description = "A path to the resource"
  default     = "path"
}

variable "request_method" {
  description = "The http request method, e.g: GET"
}

variable "authorizer_id" {
  description = "The id of the authorizer"
  default     = ""
}

variable "authorizer_type" {
  description = "Set authorizer type"
  type        = string
  default     = ""
}

variable "stage_name" {
  description = "The name of the stage to be deployed"
  default     = "dev"
}


variable "api_gateway_resource_id" {
  description = "The id of your resource , if not specified one it is going to be created"
  default     = ""
}

variable "api_gateway_resource_path" {
  description = "The path of your resource , if not specified one it is going to be created"
  default     = ""
}

variable "module_dependency" {
  default = ""
}

# -----------------------------------------------------------------------------
# Variables: CORS-related
# -----------------------------------------------------------------------------
variable "cors_enable" {
  type    = bool
  default = false
}

# var.allow_headers
variable "allow_headers" {
  description = "Allow headers"
  type        = list(string)

  default = [
    "Authorization",
    "Content-Type",
    "X-Amz-Date",
    "X-Amz-Security-Token",
    "X-Api-Key",
  ]
}

# var.allow_methods
variable "allow_methods" {
  description = "Allow methods"
  type        = list(string)

  default = [
    "OPTIONS",
    "HEAD",
    "GET",
    "POST",
    "PUT",
    "PATCH",
    "DELETE",
  ]
}

# var.allow_origin
variable "allow_origin" {
  description = "Allow origin"
  type        = string
  default     = "*"
}

# var.allow_max_age
variable "allow_max_age" {
  description = "Allow response caching time"
  type        = string
  default     = "7200"
}

# var.allowed_credentials
variable "allow_credentials" {
  description = "Allow credentials"
  default     = true
}
