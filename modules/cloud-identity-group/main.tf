# ==============================================================================
# 模块：cloud-identity-group
# 功能：云身份中心用户组封装，按职能批量授权
# 并发规避：CloudIdentity::Group CREATE 有强并发限制（ConcurrentException 高发），
#         通过 throttle_seconds 强制错开各 group 的真实调用时序。
# ==============================================================================

resource "time_sleep" "throttle" {
  create_duration = "${var.throttle_seconds}s"
}

resource "volcenginecc_cloudidentity_group" "this" {
  group_name   = var.group_name
  display_name = var.display_name
  description  = var.description
  join_type    = var.join_type

  # 成员列表通过 user_id 关联用户。Manual 类型由 IaC 维护，Auto 类型由身份源同步
  members = [
    for uid in var.member_user_ids : {
      user_id = uid
    }
  ]

  depends_on = [time_sleep.throttle]
}
