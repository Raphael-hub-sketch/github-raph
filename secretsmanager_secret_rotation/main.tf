# main.tf
# Основные ресурсы: Secrets Manager Secret, Rotation и Lambda для ротации

# ============================================================
# RANDOM ID FOR RESOURCE NAMING
# ============================================================

resource "random_id" "suffix" {
  byte_length = 4
}

# ============================================================
# SECRETS MANAGER SECRET
# ============================================================
# Основной секрет, который будет ротироваться.
# Стоимость: $0.40 за секрет в месяц [citation:9].
# ============================================================

resource "aws_secretsmanager_secret" "this" {
  name                    = local.secret_name
  description             = var.secret_description
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = local.common_tags

  # ============================================================
  # COST IMPACT: Secret Storage
  # ============================================================
  # $0.40 per secret per month [citation:9][citation:17].
  # Deleted secrets are not charged [citation:5].
  # ============================================================
}

# ============================================================
# SECRET VERSION (Initial Value)
# ============================================================
# Начальное значение секрета.
# ============================================================

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id

  secret_string = jsonencode({
    username = "admin"
    password = random_password.initial.result
    host     = "localhost"
    port     = 5432
    dbname   = "demodb"
  })

  # Важно: игнорируем изменения, так как ротация будет обновлять значение
  # Без этого Terraform будет пытаться перезаписать секрет после ротации [citation:11]
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# ============================================================
# RANDOM PASSWORD (Initial)
# ============================================================

resource "random_password" "initial" {
  length  = 32
  special = true
}

# ============================================================
# IAM ROLE FOR ROTATION LAMBDA
# ============================================================

resource "aws_iam_role" "rotation" {
  count = var.create_rotation_lambda ? 1 : 0

  name = "${local.secret_name}-rotation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags

  # ============================================================
  # COST IMPACT: IAM Role
  # ============================================================
  # IAM Roles are free.
  # ============================================================
}

# ============================================================
# IAM POLICY FOR ROTATION LAMBDA
# ============================================================

resource "aws_iam_role_policy" "rotation" {
  count = var.create_rotation_lambda ? 1 : 0

  name = "${local.secret_name}-rotation-policy"
  role = aws_iam_role.rotation[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.this.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetRandomPassword"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# ============================================================
# LAMBDA FUNCTION FOR ROTATION
# ============================================================
# Lambda-функция, которая выполняет ротацию секрета.
# Стоимость: тарифицируется по стандартным ценам Lambda [citation:5][citation:20].
# ============================================================

# Архив с кодом Lambda
data "archive_file" "rotation_lambda" {
  count = var.create_rotation_lambda ? 1 : 0

  type        = "zip"
  output_path = "${path.module}/rotation_lambda.zip"

  source {
    content  = <<-EOF
import boto3
import json
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    """
    Простая функция ротации секрета для демонстрации.
    В production используйте официальные шаблоны AWS Secrets Manager.
    """
    logger.info(f"Rotation event: {json.dumps(event)}")
    
    secret_id = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    
    client = boto3.client('secretsmanager')
    
    if step == "createSecret":
        # Создание новой версии секрета
        logger.info("Creating new secret version")
        # Здесь должна быть логика генерации нового пароля
        
    elif step == "setSecret":
        # Установка пароля в целевой системе
        logger.info("Setting secret in target system")
        
    elif step == "testSecret":
        # Проверка нового секрета
        logger.info("Testing new secret")
        
    elif step == "finishSecret":
        # Завершение ротации
        logger.info("Finishing rotation")
    
    return {"statusCode": 200, "body": "Rotation completed"}
EOF
    filename = "lambda_function.py"
  }
}

resource "aws_lambda_function" "rotation" {
  count = var.create_rotation_lambda ? 1 : 0

  filename         = data.archive_file.rotation_lambda[0].output_path
  function_name    = "${local.secret_name}-rotation"
  role             = aws_iam_role.rotation[0].arn
  handler          = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.rotation_lambda[0].output_base64sha256
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  tags = local.common_tags

  # ============================================================
  # COST IMPACT: Lambda Function
  # ============================================================
  # Lambda bills per request and per GB-second.
  # Estimated: ~$${local.monthly_lambda_cost} for ${var.monthly_rotation_invocations} invocations.
  # ============================================================
}

# ============================================================
# LAMBDA PERMISSION FOR SECRETS MANAGER
# ============================================================
# Разрешение для Secrets Manager вызывать Lambda-функцию ротации.
# ============================================================

resource "aws_lambda_permission" "secrets_manager" {
  count = var.create_rotation_lambda ? 1 : 0

  statement_id  = "AllowSecretsManagerInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation[0].function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.this.arn
}

# ============================================================
# MAIN RESOURCE: SECRETS MANAGER SECRET ROTATION
# ============================================================
# Ресурс aws_secretsmanager_secret_rotation является основным.
# Стоимость этого ресурса: $0.00 (сам ресурс бесплатен).
# ============================================================

resource "aws_secretsmanager_secret_rotation" "this" {
  count = var.enable_rotation ? 1 : 0

  secret_id           = aws_secretsmanager_secret.this.id
  rotation_lambda_arn = var.create_rotation_lambda ? aws_lambda_function.rotation[0].arn : var.existing_rotation_lambda_arn

  # ============================================================
  # ROTATION RULES
  # ============================================================
  # Правила ротации: автоматическая ротация каждые N дней [citation:1].
  # ============================================================

  rotation_rules {
    automatically_after_days = var.rotation_automatically_after_days
    duration                 = var.rotation_duration
  }

  # ============================================================
  # ИМИТАЦИЯ ЗАТРАТ ДЛЯ aws_secretsmanager_secret_rotation
  # ============================================================
  # Base Resource Cost: $0.00 (сам ресурс бесплатен)
  # Monthly Storage (${var.monthly_secret_count} secrets): ~$${local.monthly_storage_cost}
  # Monthly API Calls (${var.monthly_api_calls} calls): ~$${local.monthly_api_cost}
  # Monthly Lambda (${var.monthly_rotation_invocations} invocations): ~$${local.monthly_lambda_cost}
  # ---------------------------------
  # Estimated Monthly Total: ~$${local.estimated_monthly_cost}
  # ============================================================
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}