variable "cluster_version" {
  description = "Kubernetes version, from: aws eks describe-cluster-versions"
  type        = string
}

variable "my_ip" {
  description = "CIDR allowed to reach the Kubernetes API (same as the foundation stack)"
  type        = string
}

variable "node_instance_type" {
  type    = string
  default = "m7i-flex.large"
}
