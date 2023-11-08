variable "network_zone" {
  type    = string
  default = "eu-central"
}

variable "ipv4_range" {
  type    = string
  default = "10.0.0.0/8"
}

variable "ipv4_subnet_range" {
  type    = string
  default = "10.0.0.0/16"
}