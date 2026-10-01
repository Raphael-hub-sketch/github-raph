# locals.tf
# Локальные значения, включая имитацию расчёта затрат

locals {
  # Общие теги для всех ресурсов
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
    Resource    = "network-interface"
  }

  # ============================================================
  # ИМИТАЦИЯ РАСЧЁТА ЗАТРАТ (Cost Estimation Simulation)
  # ============================================================
  # aws_network_interface (ENI) сам по себе полностью бесплатен.
  # AWS не взимает плату за создание или использование ENI.
  #
  # Затраты могут возникать только от косвенных факторов:
  #   - Public IPv4 Address: $0.005/hour per address [citation:10]
  #   - Traffic Mirroring: $0.015/hour per ENI [citation:1]
  #   - Network Access Analyzer: $0.002 per ENI analyzed [citation:1]
  #   - IPAM Active IP: $0.00027/hour per active IP [citation:9]
  # ============================================================

  # Базовая стоимость ресурса (всегда $0.00)
  base_resource_cost = 0.00

  # Стоимость публичных IPv4-адресов
  # $0.005/hour per public IPv4 address [citation:10]
  public_ipv4_rate = 0.005
  monthly_public_ipv4_cost = var.enable_public_ip ? var.eni_count * local.public_ipv4_rate * var.monthly_hours : 0

  # Стоимость Traffic Mirroring
  # $0.015/hour per ENI with active Traffic Mirroring session [citation:1]
  traffic_mirroring_rate = 0.015
  monthly_traffic_mirroring_cost = var.enable_traffic_mirroring ? var.traffic_mirroring_sessions * local.traffic_mirroring_rate * var.monthly_hours : 0

  # Стоимость Network Access Analyzer
  # $0.002 per ENI analyzed [citation:1]
  network_access_analyzer_rate = 0.002
  monthly_network_access_analyzer_cost = var.enable_network_access_analyzer ? var.network_access_analyzer_evaluations * var.eni_count * local.network_access_analyzer_rate : 0

  # Стоимость IPAM Active IP (если используется)
  # $0.00027/hour per active IP [citation:9]
  ipam_active_ip_rate = 0.00027
  monthly_ipam_cost = 0.00  # Не используется в этом примере

  # Итоговая имитация месячных затрат
  estimated_monthly_cost = (
    local.base_resource_cost +
    local.monthly_public_ipv4_cost +
    local.monthly_traffic_mirroring_cost +
    local.monthly_network_access_analyzer_cost +
    local.monthly_ipam_cost
  )

  # ============================================================
  # СТРУКТУРА ЗАТРАТ (Cost Breakdown)
  # ============================================================
  cost_breakdown = {
    base_resource = {
      description = "aws_network_interface Resource"
      unit_price  = "$0.00 (free)"
      monthly     = local.base_resource_cost
    }
    public_ipv4 = {
      description = "Public IPv4 Addresses (${var.eni_count} ENIs)"
      unit_price  = "$0.005/hour per address"
      monthly     = local.monthly_public_ipv4_cost
    }
    traffic_mirroring = {
      description = "Traffic Mirroring (${var.traffic_mirroring_sessions} sessions)"
      unit_price  = "$0.015/hour per ENI"
      monthly     = local.monthly_traffic_mirroring_cost
    }
    network_access_analyzer = {
      description = "Network Access Analyzer (${var.network_access_analyzer_evaluations} evaluations)"
      unit_price  = "$0.002 per ENI analyzed"
      monthly     = local.monthly_network_access_analyzer_cost
    }
  }

  # ============================================================
  # РЕКОМЕНДАЦИИ ПО ОПТИМИЗАЦИИ (FinOps Recommendations)
  # ============================================================
  finops_recommendations = [
    "1. ENI полностью бесплатен — нет прямых затрат на создание или использование.",
    "2. Публичные IPv4-адреса стоят $0.005/час ($3.60/месяц) каждый, вне зависимости от привязки [citation:10].",
    "3. Traffic Mirroring стоит $0.015/час за каждый ENI с активной сессией [citation:1].",
    "4. Network Access Analyzer стоит $0.002 за каждый проанализированный ENI [citation:1].",
    "5. Удаляйте неиспользуемые ENI, чтобы избежать случайных затрат на публичные IP.",
    "6. Используйте приватные ENI без публичных IP для внутренних сервисов."
  ]
}