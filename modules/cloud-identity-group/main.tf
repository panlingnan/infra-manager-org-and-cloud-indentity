# ==============================================================================
# 模块：cloud-identity-group
# 功能：云身份中心用户组封装，按职能批量授权
# 并发规避：
#   - throttle_seconds 阶梯错开真实调用时序
#   - time_sleep.triggers 引用上游 members，强制节流计时从 users 就绪后开始，
#     避免"所有 sleep 提前结束、users 完成后所有 group 同时开火"的并发冲突
# ==============================================================================

resource "time_sleep" "throttle" {
  create_duration = "${var.throttle_seconds}s"
  # wait_for 让节流等待前一个 group 完成后再开始；upstream_members 保证用户都创建完
  triggers = {
    upstream_members = md5(jsonencode(var.member_user_ids))
    wait_for         = var.wait_for == null ? "" : tostring(var.wait_for)
  }
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
