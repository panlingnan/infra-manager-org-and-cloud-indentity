# ==============================================================================
# 局部变量
# 集中管理通用标签、节流参数
# ==============================================================================
locals {
  common_tags = [
    { key = "Project", value = var.project },
    { key = "Environment", value = var.environment },
    { key = "ManagedBy", value = "terraform" },
  ]

  # 节流单位（秒）：Cloud Control API 对 CloudIdentity/Organization 类资源存在服务端并发限制。
  # module 内 time_sleep 通过 triggers.wait_for 依赖上一层输出的哈希，
  # Terraform 图会等待上一层全部完成后才开始本层 sleep 计时，
  # 然后按业务 key 排序位置 × throttle_step 阶梯错开各实例的实际 CREATE 时刻。
  # 20s 是经验值：足以覆盖单个 CloudIdentity CREATE 端到端耗时（5-15s）。
  throttle_step = 20

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
