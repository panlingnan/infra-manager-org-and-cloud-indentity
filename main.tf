# ==============================================================================
# 项目：火山引擎云身份中心（Cloud Identity）+ 企业组织 IaC 工程
# 主入口文件：main.tf
#
# 层间串行（module-level depends_on）：
#   Cloud Control API 对 CloudIdentity/Organization 类资源有服务端并发限制。
#   Terraform 内置的 module 层 depends_on 能强制"上一层 module 完全就绪后，
#   下一层 module 才开始进入"，无需 time_sleep 兜底。
#
#   本工程编排的层次串行如下（逐层等待上层完成）：
#     organization_units       ─┐
#     organization_accounts    ─┼─┐
#     cloud_identity_users     ─┘ │
#     cloud_identity_groups    ───┼─┐
#     permission_sets          ───┘ │
#     permission_set_assignments ───┘
#
#   注意：同一 module 内部（for_each 展开的多个实例）Terraform 仍按 parallelism
#   并行创建。若该类资源实例数较多且 API 端并发限制严格，请：
#     - 依赖运行环境降低 -parallelism；或
#     - 分批拆多次 apply（-target 或缩小 tfvars 列表）
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 企业组织：组织单元（OU）
# ------------------------------------------------------------------------------
module "organization_units" {
  source   = "./modules/organization-unit"
  for_each = { for ou in var.organization_units : ou.key => ou }

  name        = each.value.name
  description = each.value.description
  parent_id   = var.root_parent_id
}

# ------------------------------------------------------------------------------
# 2. 企业组织：成员账号（等所有 OU 完成后才开始）
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

  tags = concat(each.value.tags, local.common_tags)

  # 层间串行：所有 OU 完成后再进入账号层
  depends_on = [module.organization_units]
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
}

# ------------------------------------------------------------------------------
# 4. 云身份中心：用户组（等所有 users 完成后才开始）
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

  # 层间串行：等所有 users 完成
  depends_on = [module.cloud_identity_users]
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
}

# ------------------------------------------------------------------------------
# 6. 访问授权（等所有权限集、账号、用户、组完成后才开始）
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

  # 层间串行：等所有上游层完成
  depends_on = [
    module.permission_sets,
    module.cloud_identity_users,
    module.cloud_identity_groups,
    module.organization_accounts,
  ]
}
