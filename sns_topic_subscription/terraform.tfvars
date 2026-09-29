aws_region            = "us-east-1"
environment           = "prod"
project_name          = "infra-core"
owner                 = "devops-team"
cost_center           = "CC-1042"
topic_name            = "notifications-topic"
create_topic          = true

subscriptions = [
  {
    protocol             = "sqs"
    endpoint             = "arn:aws:sqs:us-east-1:123456789012:notifications-queue"
    raw_message_delivery = true
  },
  {
    protocol = "lambda"
    endpoint = "arn:aws:lambda:us-east-1:123456789012:function:process-notification"
  },
  {
    protocol = "email"
    endpoint = "alerts@example.com"
  }
]