# ==============================================================================
# 模块：cloud-identity-user
# 功能：云身份中心（Cloud Identity）用户封装
# 并发规避：通过 throttle_seconds 错开真实调用，规避 CloudIdentity::User 并发限制
# ==============================================================================

resource "time_sleep" "throttle" {
  create_duration = "${var.throttle_seconds}s"
  # wait_for 引用前一个同类资源的 id/user_name/等，形成链式串行：
  # Terraform 图会等待 wait_for 输出可用（即上一个 user 已创建）后，才开始本 sleep 计时
  triggers = {
    user     = var.user_name
    wait_for = var.wait_for == null ? "" : tostring(var.wait_for)
  }
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
