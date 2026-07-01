# ==============================================================================
# 模块：organization-unit
# 功能：火山引擎企业组织单元（OU）封装
# 描述：单个 OU 的创建。多个 OU 由根模块 for_each 调用本模块批量管理，
#       并支持通过 parent_id 构建多层级组织树。
# 并发规避：Cloud Control API 对 Organization::Unit CREATE 有服务端并发限制，
#       模块内通过 time_sleep 按 throttle_seconds 错开真实调用时序。
# ==============================================================================

# 节流：调用者按业务 key 排序索引 × 单位延迟，得到 throttle_seconds
resource "time_sleep" "throttle" {
  create_duration = "${var.throttle_seconds}s"
}

resource "volcenginecc_organization_unit" "this" {
  parent_id   = var.parent_id
  name        = var.name
  description = var.description

  depends_on = [time_sleep.throttle]
}
