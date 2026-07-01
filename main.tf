# ==============================================================================
# 项目：火山引擎云身份中心（Cloud Identity）+ 企业组织 IaC 工程
# 主入口文件：main.tf
#
# 并发规避（上游哈希 + 阶梯 time_sleep）：
#   Cloud Control API 对 CloudIdentity/Organization 类资源有服务端并发锁。
#   本工程采用两层机制：
#     1. 每个 module 内 time_sleep 的 triggers.wait_for 引用"上一层所有实例的哈希"，
#        Terraform 图会等待上一层 module 全部完成后，本 module 的 sleep 才开始计时。
#     2. 每个实例的 throttle_seconds 按业务 key 排序位置 × throttle_step 阶梯递增，
#        计时结束时刻自然错开，实际 CREATE 调用按序发起。
#   与 count/for_each 内部自引用不同，跨 module 引用天然无环。
# ==============================================================================

# ------------------------------------------------------------------------------
# 各层"上游哈希"：只要上游任意实例发生变化，本层所有实例的 time_sleep 都会重建
# 用作 sleep 开始时刻的基准点，等价于"等所有上游完成后再开始节流"
# ------------------------------------------------------------------------------
locals {
  upstream_ou_hash      = md5(join(",", [for k in local.ou_keys : module.organization_units[k].org_unit_id]))
  upstream_user_hash    = md5(join(",", [for k in local.user_keys : module.cloud_identity_users[k].user_id]))
  upstream_account_hash = md5(join(",", [for k in local.account_keys : module.organization_accounts[k].account_id]))
  upstream_group_hash   = md5(join(",", [for k in local.group_keys : module.cloud_identity_groups[k].group_id]))
  upstream_ps_hash      = md5(join(",", [for k in local.ps_keys : module.permission_sets[k].permission_set_id]))
}

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
  # 首层无上游，wait_for 传 null
  wait_for = null
}

# ------------------------------------------------------------------------------
# 2. 企业组织：成员账号 - 等所有 OU 完成后开始阶梯节流
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

  tags             = concat(each.value.tags, local.common_tags)
  throttle_seconds = local.account_throttle[each.value.account_name]
  wait_for         = local.upstream_ou_hash
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
  wait_for                = null
}

# ------------------------------------------------------------------------------
# 4. 云身份中心：用户组 - 等所有 users 完成后开始阶梯节流
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
  wait_for         = local.upstream_user_hash
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
  wait_for            = null
}

# ------------------------------------------------------------------------------
# 6. 访问授权 - 等所有权限集/账号/用户/组完成后开始阶梯节流
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
  # 组合所有上游哈希，等这些层全部完成后再开始 sleep
  wait_for = "${local.upstream_ps_hash}|${local.upstream_user_hash}|${local.upstream_group_hash}|${local.upstream_account_hash}"
}
