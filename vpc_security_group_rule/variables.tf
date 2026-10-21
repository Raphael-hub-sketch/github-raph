variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["dev", "stage", "prod"], var.environment)
    error_message = "Allowed values: dev, stage, prod."
  }
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "infra-core"
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "CC-1042"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-0123456789abcdef0"
}

variable "security_group_id" {
  description = "Security group ID to attach rules to"
  type        = string
  default     = "sg-0123456789abcdef0"
}

variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS from internet"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP from internet"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
      description = "SSH from VPC"
    }
  ]
}

variable "egress_rules" {
  description = "List of egress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
}

variable "enable_flow_logs_simulation" {
  description = "Simulate VPC Flow Logs cost for SG traffic"
  type        = bool
  default     = true
}

variable "flow_logs_data_gb_per_month" {
  description = "Estimated Flow Logs data volume in GB per month"
  type        = number
  default     = 50
}