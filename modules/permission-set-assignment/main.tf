# ==============================================================================
# 模块：permission-set-assignment
# 功能：访问授权 + 权限集部署的原子封装
# 并发规避：assignment 与 provisioning 都对同一目标账号 + 权限集操作，服务端有串行锁。
#         通过 throttle_seconds 错开不同 assignment 的真实调用时序，避免并发冲突。
# ==============================================================================

resource "time_sleep" "throttle" {
  create_duration = "${var.throttle_seconds}s"
}

resource "volcenginecc_cloudidentity_permission_set_assignment" "this" {
  permission_set_id = var.permission_set_id
  principal_type    = var.principal_type
  principal_id      = var.principal_id
  target_id         = var.target_id

  depends_on = [time_sleep.throttle]
}

# 触发权限集到目标账号的部署：在目标账号内创建身份供应商与角色
resource "volcenginecc_cloudidentity_permission_set_provisioning" "this" {
  permission_set_id = var.permission_set_id
  target_id         = var.target_id

  # 部署逻辑上属于"授权落地"环节，显式依赖 assignment 以保证顺序
  depends_on = [volcenginecc_cloudidentity_permission_set_assignment.this]
}
