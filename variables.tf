variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "user_email" {
  description = "user email used for registration when submitting request for MC"
  type = string
  default = "user.name@address.com"
}

variable "license_id" {
  description = "Password for mission-control this is in the license file"
  type = string
  default = "license"
}
variable "username" {
  description =  "A user name that you wish to use when tagging resources"
  type = string
  default = "USERNAME"
}


variable "helm_override_file" {
  description = "the extra flie to overwrite default values in the helm installation"
  type = string
  default = "./mission-control-values/override.yaml"
}

variable "cluster_name" {
  description = "The name to give to the cluster to be provisioned"
  type = string
  default = "mc-cluster"
}
variable "platform_instance_type_db" {
  description = "The AWS instance type the platform nodes should be provisioned on"
  type = string
  default = "r6i.xlarge"
}

variable "database_instance_type_db" {
  description = "The AWS instance type the database nodes should be provisioned on"
  type = string
  default = "r6i.xlarge"
}

variable "ami_type" {
  description = "The AWS AMI type to use for the instances"
  type = string
  default = "AL2023_x86_64_STANDARD"
}

variable "loki_bucket" {
  description = "Loki S3 bucket name"
  type        = string
  default     = ""
}

variable "mimir_bucket" {
  description = "Mimir S3 bucket name"
  type        = string
  default     = ""
}