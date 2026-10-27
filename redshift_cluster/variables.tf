variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "redshift-cost-sim"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "cost_center" {
  type    = string
  default = "CC-REDSHIFT-001"
}

variable "cluster_identifier" {
  type    = string
  default = "cost-sim-redshift-cluster"
}

variable "database_name" {
  type    = string
  default = "simdb"
}

variable "master_username" {
  type    = string
  default = "adminuser"
}

variable "master_password" {
  type      = string
  sensitive = true
  default   = "SimPass123!"
}

variable "node_type" {
  type    = string
  default = "ra3.xlplus"
}

variable "number_of_nodes" {
  type    = number
  default = 2
}

variable "vpc_cidr" {
  type    = string
  default = "10.99.0.0/16"
}