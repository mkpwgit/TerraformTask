variable "internet_cidr" {
  description = "CIDR block for internet access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "local_network_cidr" {
  description = "CIDR block for the local network"
  type        = string
  default     = "10.0.0.0/16"  # Adjust the default value to match your local network
}
