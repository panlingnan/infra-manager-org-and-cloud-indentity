# ==============================================================================
# 模块：cloud-identity-user
# 功能：云身份中心（Cloud Identity）用户封装
# 并发规避：通过 throttle_seconds 错开真实调用，规避 CloudIdentity::User 并发限制
# ==============================================================================

resource "time_sleep" "throttle" {
  create_duration = "${var.throttle_seconds}s"
}

resource "volcenginecc_cloudidentity_user" "this" {
  user_name               = var.user_name
  display_name            = var.display_name
  description             = var.description
  email                   = var.email
  phone                   = var.phone
  password                = var.password
  password_reset_required = var.password_reset_required

  depends_on = [time_sleep.throttle]
}
