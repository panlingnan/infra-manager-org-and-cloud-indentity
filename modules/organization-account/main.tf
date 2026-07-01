# ==============================================================================
# 模块：organization-account
# 功能：企业组织成员账号统一管理
# 并发规避：Organization::Account CREATE 有服务端并发限制，通过 throttle_seconds
#         阶梯错开真实调用时序，避免 ConcurrentException。
# 注意：
#   1. 账号创建后无法直接删除，仅支持标记退出，请谨慎规划。
#   2. verification_relation_id 是 uint64，为空时必须 omit，不能传空字符串。
# ==============================================================================

resource "time_sleep" "throttle" {
  create_duration = "${var.throttle_seconds}s"
}

resource "volcenginecc_organization_account" "this" {
  account_name  = var.account_name
  show_name     = var.show_name
  description   = var.description
  org_unit_id   = var.org_unit_id
  allow_console = var.allow_console

  # 仅在非空时传入 verification_relation_id，避免空字符串触发 uint64 反序列化错误
  verification_relation_id = var.verification_relation_id == "" ? null : var.verification_relation_id

  tags = var.tags

  depends_on = [time_sleep.throttle]
}
