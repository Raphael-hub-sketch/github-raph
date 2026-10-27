locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    CostCenter  = var.cost_center
    ManagedBy   = "terraform"
    CostSimulation = "enabled"
  }

  redshift_tags = merge(local.common_tags, {
    Service       = "redshift"
    ResourceType  = "cluster"
    SimulatedCost = "per-node-hourly"
    NodeType      = var.node_type
    NodeCount     = tostring(var.number_of_nodes)
    CostModel     = "ra3-xlplus-simulated"
  })
}