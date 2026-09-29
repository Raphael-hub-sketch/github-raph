# =====================================================================
# SNS Topic Policy
# =====================================================================
resource "aws_sns_topic_policy" "main" {
  count = var.create_topic_policy ? 1 : 0

  arn = aws_sns_topic.main.arn

  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count = var.create_topic_policy ? 1 : 0

  policy_id = "__default_policy_ID"

  statement {
    sid    = "AllowPublish"
    effect = "Allow"

    actions = [
      "SNS:Publish",
    ]

    principals {
      type        = "AWS"
      identifiers = var.allowed_publish_principals
    }

    resources = [
      aws_sns_topic.main.arn,
    ]
  }

  statement {
    sid    = "AllowOwnerManagement"
    effect = "Allow"

    actions = [
      "SNS:Subscribe",
      "SNS:SetTopicAttributes",
      "SNS:RemovePermission",
      "SNS:Receive",
      "SNS:Publish",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:AddPermission",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"

      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    resources = [
      aws_sns_topic.main.arn,
    ]
  }
}

data "aws_caller_identity" "current" {}