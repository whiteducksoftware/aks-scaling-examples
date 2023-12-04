################################
############ Common ############
################################

variable "stage" {
  description = "(Required) one of stg, dev or prd."
  type        = string
  default     = "scale"
}

variable "prefix" {
  description = "(Required) The prefix for the resources created in the specified Azure Resource Group"
  type        = string
  default     = "pwe"
}

# resource location
variable "location" {
  description = "The location used for all resources"
  type        = string
  default     = "northeurope"

}
