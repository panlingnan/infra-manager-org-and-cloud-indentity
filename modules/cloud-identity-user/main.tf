# ==============================================================================
# 模块：cloud-identity-user
# 功能：云身份中心（Cloud Identity）用户封装
# ==============================================================================
resource "volcenginecc_cloudidentity_user" "this" {
  user_name               = var.user_name
  display_name            = var.display_name
  description             = var.description
  email                   = var.email
  phone                   = var.phone
  password                = var.password
  password_reset_required = var.password_reset_required
}
