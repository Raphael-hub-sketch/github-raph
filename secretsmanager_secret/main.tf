# =====================================================================
# Secrets Manager Secret (основной ресурс)
# ---------------------------------------------------------------------
# Управляет метаданными секрета. Для значения используйте
# aws_secretsmanager_secret_version.
# =====================================================================
resource "aws_secretsmanager_secret" "main" {
  name        = var.secret_name
  description = var.secret_description

  recovery_window_in_days = var.recovery_window_in_days

  kms_key_id = var.kms_key_id

  # Multi-region replication (каждая реплика тарифицируется как отдельный секрет)
  dynamic "replica" {
    for_each = var.enable_replication ? var.replica_regions : []
    content {
      region = replica.value
    }
  }

  tags = merge(local.common_tags, {
    Name = var.secret_name
  })
}

# =====================================================================
# Random Password (генерация значения секрета)
# =====================================================================
resource "random_password" "secret_value" {
  count = var.create_secret_version ? 1 : 0

  length  = 32
  special = true
}

# =====================================================================
# Secrets Manager Secret Version (значение секрета)
# =====================================================================
resource "aws_secretsmanager_secret_version" "main" {
  count = var.create_secret_version ? 1 : 0

  secret_id = aws_secretsmanager_secret.main.id

  secret_string = jsonencode({
    username = var.secret_username
    password = random_password.secret_value[0].result
    host     = var.secret_host
    port     = var.secret_port
    dbname   = var.secret_dbname
  })

  # Критично: игнорировать изменения после создания
  # Rotation Lambda будет обновлять значение, Terraform не должен его перезаписывать
  lifecycle {
    ignore_changes = [secret_string]
  }
}

# =====================================================================
# ИМИТАЦИЯ ЗАТРАТ (Cost Simulation)
# ---------------------------------------------------------------------
# Ниже — развёрнутый блок, документирующий предполагаемые расходы.
# Он не влияет на инфраструктуру, но служит единым источником правды
# для FinOps-команды и может быть распарсен внешними скриптами
# (например, через `terraform output -json cost_report`).
# =====================================================================

locals {
  # ------------------------------------------------------------------
  # СЕКЦИЯ 1: Справочник цен AWS Secrets Manager (us-east-1, 2024-2025)
  # Источник: https://aws.amazon.com/secretsmanager/pricing/ [citation:2]
  # ------------------------------------------------------------------
  secrets_pricing = {
    # Хранение секретов
    secret_per_month_usd          = 0.40   # $0.40 за секрет в месяц [citation:6][citation:18]
    secret_per_hour_usd           = 0.40 / 730 # пропорционально часам

    # API-вызовы
    api_calls_per_10k_usd         = 0.05   # $0.05 за 10 000 вызовов [citation:10][citation:14]
    api_calls_free_tier           = 0      # нет постоянного free tier [citation:18]

    # Реплики (каждая реплика = отдельный секрет)
    replica_per_month_usd         = 0.40   # каждая реплика тарифицируется как секрет [citation:18]

    # KMS (если используется свой CMK)
    kms_cmk_per_month_usd         = 1.00   # $1/мес за CMK
    kms_api_calls_per_10k_usd     = 0.03   # $0.03 за 10 000 KMS-вызовов

    # Rotation Lambda (тарифицируется Lambda отдельно)
    rotation_lambda_monthly_usd   = 0.20   # оценка для低频 rotation

    # Часов в месяце (30 дней)
    hours_per_month               = 730
    hours_per_year                = 8760
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 2: Прогнозируемое потребление (имитация)
  # ------------------------------------------------------------------
  secrets_usage = {
    # Количество секретов (включая основной и реплики)
    secrets_count                 = 1
    replicas_count                = var.enable_replication ? length(var.replica_regions) : 0

    # API-вызовы в месяц
    monthly_api_calls             = 100000  # 100K вызовов/мес
    # Если приложение кэширует секреты, вызовов значительно меньше
    cache_enabled                 = true
    cache_reduction_percent       = 95     # кэширование снижает вызовы на 90-99% [citation:6]

    # Используется ли свой KMS CMK
    custom_kms                    = var.kms_key_id != null

    # Включена ли rotation
    rotation_enabled              = false
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 3: Детализированный расчёт затрат (построчный)
  # ------------------------------------------------------------------
  cost_breakdown = {
    # --- Хранение секретов ---
    secret_storage = {
      description = "Secrets Manager: хранение (${local.secrets_usage.secrets_count} секрет)"
      quantity    = local.secrets_usage.secrets_count
      unit_price  = local.secrets_pricing.secret_per_month_usd
      monthly_usd = local.secrets_usage.secrets_count * local.secrets_pricing.secret_per_month_usd
      yearly_usd  = local.secrets_usage.secrets_count * local.secrets_pricing.secret_per_month_usd * 12
      notes       = "Нет постоянного free tier [citation:18]"
    }

    # --- Хранение реплик ---
    replica_storage = {
      description = "Secrets Manager: реплики (${local.secrets_usage.replicas_count} шт.)"
      quantity    = local.secrets_usage.replicas_count
      unit_price  = local.secrets_pricing.replica_per_month_usd
      monthly_usd = local.secrets_usage.replicas_count * local.secrets_pricing.replica_per_month_usd
      yearly_usd  = local.secrets_usage.replicas_count * local.secrets_pricing.replica_per_month_usd * 12
      notes       = "Каждая реплика тарифицируется как отдельный секрет [citation:18]"
    }

    # --- API-вызовы ---
    api_calls = {
      description = "Secrets Manager: API-вызовы"
      quantity    = local.secrets_usage.monthly_api_calls
      unit_price  = local.secrets_pricing.api_calls_per_10k_usd
      monthly_usd = local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.api_calls_per_10k_usd
      yearly_usd  = local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.api_calls_per_10k_usd * 12
      notes       = "$0.05 за 10 000 вызовов [citation:10]"
    }

    # --- KMS CMK (если используется) ---
    kms_cmk = {
      description = "KMS CMK (custom key)"
      quantity    = local.secrets_usage.custom_kms ? 1 : 0
      unit_price  = local.secrets_pricing.kms_cmk_per_month_usd
      monthly_usd = local.secrets_usage.custom_kms ? local.secrets_pricing.kms_cmk_per_month_usd : 0
      yearly_usd  = local.secrets_usage.custom_kms ? local.secrets_pricing.kms_cmk_per_month_usd * 12 : 0
      notes       = "Только при использовании своего CMK вместо aws/secretsmanager"
    }

    # --- KMS API calls ---
    kms_api_calls = {
      description = "KMS API calls (для шифрования/расшифровки)"
      quantity    = local.secrets_usage.custom_kms ? local.secrets_usage.monthly_api_calls : 0
      unit_price  = local.secrets_pricing.kms_api_calls_per_10k_usd
      monthly_usd = local.secrets_usage.custom_kms ? local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.kms_api_calls_per_10k_usd : 0
      yearly_usd  = local.secrets_usage.custom_kms ? local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.kms_api_calls_per_10k_usd * 12 : 0
      notes       = "Каждый GetSecretValue вызывает KMS Decrypt при custom CMK"
    }

    # --- Rotation Lambda ---
    rotation_lambda = {
      description = "Rotation Lambda (оценка)"
      quantity    = local.secrets_usage.rotation_enabled ? 1 : 0
      unit_price  = local.secrets_pricing.rotation_lambda_monthly_usd
      monthly_usd = local.secrets_usage.rotation_enabled ? local.secrets_pricing.rotation_lambda_monthly_usd : 0
      yearly_usd  = local.secrets_usage.rotation_enabled ? local.secrets_pricing.rotation_lambda_monthly_usd * 12 : 0
      notes       = "Lambda тарифицируется отдельно [citation:18]"
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 4: Итоговые суммы (имитация)
  # ------------------------------------------------------------------
  cost_monthly_total = sum([
    for k, v in local.cost_breakdown : v.monthly_usd
  ])

  cost_yearly_total = sum([
    for k, v in local.cost_breakdown : v.yearly_usd
  ])

  cost_currency = "USD"

  # ------------------------------------------------------------------
  # СЕКЦИЯ 5: Построчная детализация по каждому элементу затрат
  # ------------------------------------------------------------------
  cost_line_items = [
    {
      line_no     = 1
      service     = "SecretsManager"
      component   = "SecretStorage"
      description = "Хранение секрета"
      unit        = "per secret/month"
      quantity    = local.secrets_usage.secrets_count
      unit_price  = local.secrets_pricing.secret_per_month_usd
      monthly_usd = local.secrets_usage.secrets_count * local.secrets_pricing.secret_per_month_usd
      yearly_usd  = local.secrets_usage.secrets_count * local.secrets_pricing.secret_per_month_usd * 12
      notes       = "Нет free tier [citation:18]"
    },
    {
      line_no     = 2
      service     = "SecretsManager"
      component   = "ReplicaStorage"
      description = "Хранение реплик"
      unit        = "per replica/month"
      quantity    = local.secrets_usage.replicas_count
      unit_price  = local.secrets_pricing.replica_per_month_usd
      monthly_usd = local.secrets_usage.replicas_count * local.secrets_pricing.replica_per_month_usd
      yearly_usd  = local.secrets_usage.replicas_count * local.secrets_pricing.replica_per_month_usd * 12
      notes       = "Каждая реплика = отдельный секрет [citation:18]"
    },
    {
      line_no     = 3
      service     = "SecretsManager"
      component   = "APICalls"
      description = "API-вызовы (${local.secrets_usage.monthly_api_calls} шт./мес)"
      unit        = "per 10k calls"
      quantity    = local.secrets_usage.monthly_api_calls
      unit_price  = local.secrets_pricing.api_calls_per_10k_usd
      monthly_usd = local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.api_calls_per_10k_usd
      yearly_usd  = local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.api_calls_per_10k_usd * 12
      notes       = "Кэширование снижает на 90-99% [citation:6]"
    },
    {
      line_no     = 4
      service     = "KMS"
      component   = "CMK"
      description = "KMS CMK (custom key)"
      unit        = "per CMK/month"
      quantity    = local.secrets_usage.custom_kms ? 1 : 0
      unit_price  = local.secrets_pricing.kms_cmk_per_month_usd
      monthly_usd = local.secrets_usage.custom_kms ? local.secrets_pricing.kms_cmk_per_month_usd : 0
      yearly_usd  = local.secrets_usage.custom_kms ? local.secrets_pricing.kms_cmk_per_month_usd * 12 : 0
      notes       = "Только для custom CMK"
    },
    {
      line_no     = 5
      service     = "KMS"
      component   = "APICalls"
      description = "KMS API calls"
      unit        = "per 10k calls"
      quantity    = local.secrets_usage.custom_kms ? local.secrets_usage.monthly_api_calls : 0
      unit_price  = local.secrets_pricing.kms_api_calls_per_10k_usd
      monthly_usd = local.secrets_usage.custom_kms ? local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.kms_api_calls_per_10k_usd : 0
      yearly_usd  = local.secrets_usage.custom_kms ? local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.kms_api_calls_per_10k_usd * 12 : 0
      notes       = "При custom CMK каждый GetSecretValue = KMS Decrypt"
    },
  ]

  # ------------------------------------------------------------------
  # СЕКЦИЯ 6: Расширенная разбивка по категориям (для дашбордов)
  # ------------------------------------------------------------------
  cost_by_category = {
    "Secrets.Storage"   = local.secrets_usage.secrets_count * local.secrets_pricing.secret_per_month_usd
    "Secrets.Replicas"  = local.secrets_usage.replicas_count * local.secrets_pricing.replica_per_month_usd
    "Secrets.API"       = local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.api_calls_per_10k_usd
    "KMS.CMK"           = local.secrets_usage.custom_kms ? local.secrets_pricing.kms_cmk_per_month_usd : 0
    "KMS.API"           = local.secrets_usage.custom_kms ? local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.kms_api_calls_per_10k_usd : 0
    "Rotation"          = local.secrets_usage.rotation_enabled ? local.secrets_pricing.rotation_lambda_monthly_usd : 0
  }

  cost_by_service = {
    "SecretsManager" = (local.secrets_usage.secrets_count * local.secrets_pricing.secret_per_month_usd) + (local.secrets_usage.replicas_count * local.secrets_pricing.replica_per_month_usd) + (local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.api_calls_per_10k_usd)
    "KMS"            = (local.secrets_usage.custom_kms ? local.secrets_pricing.kms_cmk_per_month_usd : 0) + (local.secrets_usage.custom_kms ? local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.kms_api_calls_per_10k_usd : 0)
    "Lambda"         = local.secrets_usage.rotation_enabled ? local.secrets_pricing.rotation_lambda_monthly_usd : 0
  }

  cost_by_environment = {
    "${var.environment}" = local.cost_monthly_total
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 7: Прогноз на 12 месяцев (имитация)
  # ------------------------------------------------------------------
  monthly_forecast = [
    for m in range(1, 13) : {
      month        = m
      month_name   = element([
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
      ], m - 1)
      base_usd     = local.cost_monthly_total
      growth_rate  = 0.02 # 2% ежемесячный рост трафика
      projected_usd = local.cost_monthly_total * pow(1.02, m - 1)
    }
  ]

  yearly_projection = {
    total_usd       = sum([for m in local.monthly_forecast : m.projected_usd])
    average_monthly = sum([for m in local.monthly_forecast : m.projected_usd]) / 12
    peak_month      = max([for m in local.monthly_forecast : m.projected_usd]...)
    lowest_month    = min([for m in local.monthly_forecast : m.projected_usd]...)
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 8: Сравнение сценариев (What-If analysis)
  # ------------------------------------------------------------------
  scenario_comparison = {
    "current" = {
      description          = "Текущая конфигурация (${local.secrets_usage.secrets_count} секрет, ${local.secrets_usage.monthly_api_calls} вызовов)"
      secrets_count        = local.secrets_usage.secrets_count
      monthly_api_calls    = local.secrets_usage.monthly_api_calls
      monthly_usd          = local.cost_monthly_total
    }
    "cached" = {
      description          = "С кэшированием (снижение вызовов на 95%)"
      secrets_count        = local.secrets_usage.secrets_count
      monthly_api_calls    = local.secrets_usage.monthly_api_calls * 0.05
      monthly_usd          = (local.secrets_usage.secrets_count * local.secrets_pricing.secret_per_month_usd) + (local.secrets_usage.monthly_api_calls * 0.05 / 10000 * local.secrets_pricing.api_calls_per_10k_usd)
    }
    "no_cache" = {
      description          = "Без кэширования (100K вызовов)"
      secrets_count        = local.secrets_usage.secrets_count
      monthly_api_calls    = 100000
      monthly_usd          = (local.secrets_usage.secrets_count * local.secrets_pricing.secret_per_month_usd) + (100000 / 10000 * local.secrets_pricing.api_calls_per_10k_usd)
    }
    "with_replicas" = {
      description          = "С multi-region replication (2 реплики)"
      secrets_count        = local.secrets_usage.secrets_count
      monthly_api_calls    = local.secrets_usage.monthly_api_calls
      monthly_usd          = local.cost_monthly_total + (2 * local.secrets_pricing.replica_per_month_usd)
    }
    "with_custom_kms" = {
      description          = "С custom KMS CMK"
      secrets_count        = local.secrets_usage.secrets_count
      monthly_api_calls    = local.secrets_usage.monthly_api_calls
      monthly_usd          = local.cost_monthly_total + local.secrets_pricing.kms_cmk_per_month_usd + (local.secrets_usage.monthly_api_calls / 10000 * local.secrets_pricing.kms_api_calls_per_10k_usd)
    }
    "parameter_store" = {
      description          = "Альтернатива: SSM Parameter Store Standard (бесплатно)"
      secrets_count        = 0
      monthly_api_calls    = local.secrets_usage.monthly_api_calls
      monthly_usd          = 0.00
    }
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 9: Алерты и пороги (имитация для AWS Budgets)
  # ------------------------------------------------------------------
  budget_thresholds = {
    monthly_warning      = 10.00
    monthly_critical     = 25.00
    yearly_max           = 300.00
    notify_emails        = ["finops@example.com", "devops@example.com"]
    alert_on_breach      = true
    api_calls_warning    = 500000
    api_calls_crit       = 1000000
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 10: Метаданные отчёта
  # ------------------------------------------------------------------
  cost_report_metadata = {
    generated_by       = "terraform"
    project            = var.project_name
    environment        = var.environment
    secret_name        = var.secret_name
    aws_region         = var.aws_region
    currency           = local.cost_currency
    pricing_source     = "https://aws.amazon.com/secretsmanager/pricing/ [citation:2]"
    pricing_date       = "2025-01-01"
    report_version     = "1.0.0"
    disclaimer         = "Это имитация. Для точных цифр используйте Infracost / AWS Cost Explorer."
    billing_note       = "Secrets Manager bills per secret per month ($0.40) + API calls ($0.05/10K). No free tier [citation:18]"
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 11: Проверка лимитов и квот (имитация)
  # Источник: AWS Secrets Manager quotas [citation:16][citation:20]
  # ------------------------------------------------------------------
  quota_checks = {
    max_secrets_per_region        = 500000
    max_secret_size_bytes         = 65536
    max_versions_per_secret       = 100
    max_staging_labels            = 20
    max_policy_size_chars         = 20480
    current_secrets               = local.secrets_usage.secrets_count
    current_secret_size_bytes     = 256  # оценка для JSON
    secrets_ok                    = local.secrets_usage.secrets_count <= 500000
    secret_size_ok                = 256 <= 65536
  }

  # ------------------------------------------------------------------
  # СЕКЦИЯ 12: Сравнение с SSM Parameter Store (для документации)
  # ------------------------------------------------------------------
  parameter_store_comparison = {
    "SecretsManager" = {
      price_per_secret_month  = "$0.40"
      price_per_10k_calls     = "$0.05"
      free_tier               = "None"
      rotation                = "Built-in (RDS, Redshift, DocumentDB)"
      cross_region_replication = "Yes (each replica billed)"
      use_cases               = "Credentials that need rotation [citation:6]"
    }
    "ParameterStore.Standard" = {
      price_per_secret_month  = "Free"
      price_per_10k_calls     = "Free"
      free_tier               = "Unlimited (10K params)"
      rotation                = "Not built-in"
      cross_region_replication = "No"
      use_cases               = "Config, flags, static values [citation:6]"
    }
    "ParameterStore.Advanced" = {
      price_per_secret_month  = "$0.05"
      price_per_10k_calls     = "Free (standard throughput)"
      free_tier               = "None"
      rotation                = "Not built-in"
      cross_region_replication = "No"
      use_cases               = "Larger params (>4KB), policies [citation:14]"
    }
  }
}