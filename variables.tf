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

variable "subnet1_cidr" {
  description = "CIDR block for the subnet1"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet2_cidr" {
    description = "CIDR block for the subnet2"
    type        = string
    default     = "10.0.2.0/24"
}
