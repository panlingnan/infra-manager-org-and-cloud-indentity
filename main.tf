# ==============================================================================
# 项目：火山引擎云身份中心（Cloud Identity）+ 企业组织 IaC 工程
# 主入口文件：main.tf
# 描述：基于 volcenginecc Provider 实现：
#   1. 企业组织树（OU + 成员账号）的批量编排
#   2. 云身份中心用户与用户组的全生命周期管理
#   3. 访问权限集（Permission Set）模板化定义
#   4. 用户/组 × 目标账号 × 权限集的访问授权与部署同步
# 并发规避：每个 module 内部使用 time_sleep 按业务 key 排序位置错开真实 API 调用，
#         规避 Cloud Control API 对 CloudIdentity/Organization 类资源的服务端并发限制，
#         无需外部指定 -parallelism=1 也能稳定 apply。
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 企业组织：组织单元（OU）
# ------------------------------------------------------------------------------
module "organization_units" {
  source   = "./modules/organization-unit"
  for_each = { for ou in var.organization_units : ou.key => ou }

  name             = each.value.name
  description      = each.value.description
  parent_id        = var.root_parent_id
  throttle_seconds = local.ou_throttle[each.key]
}

# ------------------------------------------------------------------------------
# 2. 企业组织：成员账号
# ------------------------------------------------------------------------------
module "organization_accounts" {
  source   = "./modules/organization-account"
  for_each = { for acc in var.organization_accounts : acc.account_name => acc }

  account_name             = each.value.account_name
  show_name                = each.value.show_name
  description              = each.value.description
  allow_console            = each.value.allow_console
  verification_relation_id = each.value.verification_relation_id
  org_unit_id              = each.value.org_unit_key == "" ? var.root_parent_id : module.organization_units[each.value.org_unit_key].org_unit_id

  # 合并资源标签：业务自定义标签 + 工程通用标签
  tags             = concat(each.value.tags, local.common_tags)
  throttle_seconds = local.account_throttle[each.value.account_name]
}

# ------------------------------------------------------------------------------
# 3. 云身份中心：用户
# ------------------------------------------------------------------------------
module "cloud_identity_users" {
  source   = "./modules/cloud-identity-user"
  for_each = { for u in var.cloud_identity_users : u.key => u }

  user_name               = each.value.user_name
  display_name            = each.value.display_name
  description             = each.value.description
  email                   = each.value.email
  phone                   = each.value.phone
  password                = each.value.password
  password_reset_required = each.value.password_reset_required
  throttle_seconds        = local.user_throttle[each.key]
}

# ------------------------------------------------------------------------------
# 4. 云身份中心：用户组
# ------------------------------------------------------------------------------
module "cloud_identity_groups" {
  source   = "./modules/cloud-identity-group"
  for_each = { for g in var.cloud_identity_groups : g.key => g }

  group_name   = each.value.group_name
  display_name = each.value.display_name
  description  = each.value.description
  join_type    = each.value.join_type

  member_user_ids = [
    for member_key in each.value.member_keys : module.cloud_identity_users[member_key].user_id
  ]
  throttle_seconds = local.group_throttle[each.key]
}

# ------------------------------------------------------------------------------
# 5. 云身份中心：访问权限集
# ------------------------------------------------------------------------------
module "permission_sets" {
  source   = "./modules/permission-set"
  for_each = { for ps in var.permission_sets : ps.key => ps }

  name                = each.value.name
  description         = each.value.description
  session_duration    = each.value.session_duration
  relay_state         = each.value.relay_state
  permission_policies = each.value.permission_policies
  throttle_seconds    = local.ps_throttle[each.key]
}

# ------------------------------------------------------------------------------
# 6. 访问授权：将权限集授予用户/组对目标账号的访问权限
# ------------------------------------------------------------------------------
module "permission_set_assignments" {
  source = "./modules/permission-set-assignment"
  for_each = {
    for a in var.permission_set_assignments :
    "${a.permission_set_key}|${a.principal_type}|${a.principal_key}|${a.target_account_key != "" ? a.target_account_key : a.target_account_id}" => a
  }

  permission_set_id = module.permission_sets[each.value.permission_set_key].permission_set_id
  principal_type    = each.value.principal_type
  principal_id = (each.value.principal_type == "User"
    ? module.cloud_identity_users[each.value.principal_key].user_id
    : module.cloud_identity_groups[each.value.principal_key].group_id
  )
  target_id = (each.value.target_account_key != ""
    ? module.organization_accounts[each.value.target_account_key].account_id
    : each.value.target_account_id
  )
  throttle_seconds = local.assignment_throttle[each.key]
}
