variable "aws_region" {
  type    = string
  default = "us-east-1"
  description = "Primary AWS Region"
}

variable "aws_region_dr" {
  type    = string
  default = "us-west-2"
  description = "Secondary AWS Region for Disaster Recovery"
}

variable "admin_email" {
  type    = string
  default = "naur.ok0805@gmail.com"
  description = "Admin email for SNS alerts"
}

variable "external_email" {
  type    = string
  default = "abendgast@gmail.com"
  description = "External user email"
}

variable "key_name" {
  type    = string
  default = "az104_lab_key"
  description = "SSH key pair name"
}

variable "public_key_path" {
  type    = string
  default = "/home/abd/.ssh/id_ed25519.pub"
  description = "Path to public SSH key"
}
