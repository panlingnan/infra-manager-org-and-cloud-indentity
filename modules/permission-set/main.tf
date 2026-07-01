# ==============================================================================
# 模块：permission-set
# 功能：云身份中心访问权限集封装
# 设计要点：
#   - permission_policies 是 SetNestedAttribute，必须完整定义所有字段
#   - session_duration 单位为秒，建议 3600 或更长以适配长会话场景
# ==============================================================================
resource "volcenginecc_cloudidentity_permission_set" "this" {
  name             = var.name
  description      = var.description
  session_duration = var.session_duration
  relay_state      = var.relay_state

  permission_policies = [
    for p in var.permission_policies : {
      permission_policy_name     = p.permission_policy_name
      permission_policy_type     = p.permission_policy_type
      permission_policy_document = p.permission_policy_document
    }
  ]
}
