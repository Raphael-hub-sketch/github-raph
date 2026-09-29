# =====================================================================
# Secrets Manager Secret Policy (опционально)
# =====================================================================
resource "aws_secretsmanager_secret_policy" "main" {
  count = var.create_policy ? 1 : 0

  secret_arn = aws_secretsmanager_secret.main.arn

  policy = data.aws_iam_policy_document.secret_policy[0].json
}

data "aws_iam_policy_document" "secret_policy" {
  count = var.create_policy ? 1 : 0

  statement {
    sid    = "AllowReadAccess"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]

    principals {
      type        = "AWS"
      identifiers = var.allowed_read_principals
    }

    resources = [
      aws_secretsmanager_secret.main.arn,
    ]
  }
}