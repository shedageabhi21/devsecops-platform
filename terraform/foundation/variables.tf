variable "my_ip" {
  description = "Your public IP with /32, e.g. 203.0.113.10/32"
  type        = string
}

variable "key_name" {
  description = "Existing EC2 key pair name in ap-south-1"
  type        = string
}
