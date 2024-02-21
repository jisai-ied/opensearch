variable "aws_region" {
  default = "eu-west-1"
  type = string
}

variable "hosted_zone_id" {
  type = string
}

variable "environment" {
    default = "dev"
}

variable "service" {
  type = string
}

//! ATTENTION IN FUTURE SHOULD USE TERRAFORM REMOTE STORAGE
variable "cidr_block" {
  description = "The CIDR block for the VPC. ATTENTION!"
  default     = "10.0.0.0/16"
  type        = string
}

// --- AWS Opensearch Domain ---
variable "domain" {
    description = "Opensearch Engine Name"
    type = string
}

variable "engine_version" {
  type = string
}


// -- EBS OPTIONS --
variable "ebs_enabled" { 
    type = bool 
}
variable "ebs_volume_size" { 
    type = number 
}
variable "volume_type" { 
    type = string 
}

variable "throughput" { 
    type = number 
}

variable "instance_type" {
  type = string
}

variable "instance_count" {
  type = number
}
// -- END EBS OPTIONS --


// -- CLUSTER CONFIG --
variable "dedicated_master_enabled" {
  type = bool
  default = false
}

variable "dedicated_master_count" {
  type = number
  default = 0
}

variable "dedicated_master_type" {
  type = string
  default = null
}

variable "zone_awareness_enabled" {
  type = bool
  default = false
}
// -- END CLUSTER CONFIG --

// -- ADVANCED SECURITY OPTIONS --
variable "master_user" {
  type = string
    default = "master_user"
}

variable "security_options_enabled" { type = bool }
// -- END ADVANCED SECURITY OPTIONS --