# ==============================================================================
# 局部变量
# 集中管理通用标签、节流参数、跨模块查找映射
# ==============================================================================
locals {
  # 全局通用标签：所有支持 Tags 的资源统一打标，便于审计与成本归集
  common_tags = [
    { key = "Project", value = var.project },
    { key = "Environment", value = var.environment },
    { key = "ManagedBy", value = "terraform" },
  ]

  # 节流单位（秒）：Cloud Control API 对 CloudIdentity/Organization 类资源存在服务端并发限制，
  # 通过 time_sleep 按业务 key 排序位置阶梯递增，错开真实 API 调用时序。
  throttle_step = 8

  # 各资源按业务 key 排序后计算索引 → 索引 × throttle_step = 每个实例的等待秒数。
  # 索引 0 立即执行，后续实例依次错开，避免 ConcurrentException。
  ou_keys     = sort([for ou in var.organization_units : ou.key])
  ou_throttle = { for i, k in local.ou_keys : k => i * local.throttle_step }

  account_keys     = sort([for a in var.organization_accounts : a.account_name])
  account_throttle = { for i, k in local.account_keys : k => i * local.throttle_step }

  user_keys     = sort([for u in var.cloud_identity_users : u.key])
  user_throttle = { for i, k in local.user_keys : k => i * local.throttle_step }

  group_keys     = sort([for g in var.cloud_identity_groups : g.key])
  group_throttle = { for i, k in local.group_keys : k => i * local.throttle_step }

  ps_keys     = sort([for ps in var.permission_sets : ps.key])
  ps_throttle = { for i, k in local.ps_keys : k => i * local.throttle_step }

  assignment_keys = sort([
    for a in var.permission_set_assignments :
    "${a.permission_set_key}|${a.principal_type}|${a.principal_key}|${a.target_account_key != "" ? a.target_account_key : a.target_account_id}"
  ])
  assignment_throttle = { for i, k in local.assignment_keys : k => i * local.throttle_step }
}
