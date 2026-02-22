provider "aws" {
  region = "us-east-1" # Change to your desired region
}

# Create an IAM role
resource "aws_iam_role" "example" {
  name = "example-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ExampleIAMRole"
  }
}

# Create an IAM role policy
resource "aws_iam_role_policy" "example_policy" {
  name   = "example-policy"
  role   = aws_iam_role.example.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:ListBucket", "s3:GetObject"],
        Resource = [
          "arn:aws:s3:::example-bucket",
          "arn:aws:s3:::example-bucket/*"
        ]
      }
    ]
  })
}

output "iam_role_name" {
  value = aws_iam_role.example.name
}

output "iam_role_policy_name" {
  value = aws_iam_role_policy.example_policy.name
}
