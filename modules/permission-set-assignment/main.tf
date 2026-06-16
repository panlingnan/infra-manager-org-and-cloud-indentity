# ==============================================================================
# 模块：permission-set-assignment
# 功能：访问授权 + 权限集部署的原子封装
# 描述：把"用户/组 × 目标账号 × 权限集"绑定为一条访问授权，并触发权限集到目标账号的部署。
#       一条授权由两个资源组成：
#         1. permission_set_assignment：声明授权关系（principal -> target）
#         2. permission_set_provisioning：将权限集同步到目标账号（创建身份供应商 / 角色）
# 设计要点：
#   - 部署需在授权之后或并行进行；这里通过 depends_on 显式编排部署在授权之后
# ==============================================================================
resource "volcenginecc_cloudidentity_permission_set_assignment" "this" {
  permission_set_id = var.permission_set_id
  principal_type    = var.principal_type
  principal_id      = var.principal_id
  target_id         = var.target_id
}

# 触发权限集到目标账号的部署：在目标账号内创建身份供应商与角色
resource "volcenginecc_cloudidentity_permission_set_provisioning" "this" {
  permission_set_id = var.permission_set_id
  target_id         = var.target_id

  # 部署逻辑上属于"授权落地"环节，显式依赖 assignment 以保证顺序
  depends_on = [volcenginecc_cloudidentity_permission_set_assignment.this]
}
