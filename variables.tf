# #########################################
# Configuration
# #########################################
variable "aws_region" {
  default = "eu-central-1"
}

variable "customer_tla" {
  type        = string
  default     = "lv"
  description = "The three-letter-acronym to be used for the customer"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "The environment in which to deploy the resources"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to apply to the resource"
  default     = {}
}
