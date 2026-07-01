# ==============================================================================
# 局部变量
# ==============================================================================
locals {
  # 全局通用标签：所有支持 Tags 的资源统一打标，便于审计与成本归集
  common_tags = [
    { key = "Project", value = var.project },
    { key = "Environment", value = var.environment },
    { key = "ManagedBy", value = "terraform" },
  ]
}
