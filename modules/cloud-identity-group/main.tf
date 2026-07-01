# ==============================================================================
# 模块：cloud-identity-group
# 功能：云身份中心用户组封装，按职能批量授权
# ==============================================================================
resource "volcenginecc_cloudidentity_group" "this" {
  group_name   = var.group_name
  display_name = var.display_name
  description  = var.description
  join_type    = var.join_type

  members = [
    for uid in var.member_user_ids : {
      user_id = uid
    }
  ]
}
