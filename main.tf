# ==============================================================================
# 项目：火山引擎云身份中心（Cloud Identity）+ 企业组织 IaC 工程
# 主入口文件：main.tf
#
# 并发规避方案：静态 module 串联
# ------------------------------------------------------------------------------
# Cloud Control API 对 CloudIdentity/Organization 类资源有严格的服务端并发锁；
# 而 volcenginecc provider 不支持 retry 配置，inframanager 也不允许覆盖
# -parallelism。因此本工程将每类资源"完全展开"为多个静态 module 块，
# 并在 module 声明处用 depends_on 显式串联，让 Terraform 图天然逐个创建：
#
#   module.ou_1 → module.ou_2 → module.account_1 → module.account_2
#   module.user_1 → module.user_2 → module.group_1 → module.group_2
#   module.ps_1  → module.ps_2  → module.assignment_1 → assignment_2 → 3
#
# 效果：
#   1. 任意两个资源之间 API 调用必然串行，100% 规避 ConcurrentException
#   2. 无需 time_sleep / null_resource / 外部重试
#   3. 不依赖运行环境（inframanager 无需改任何参数）
#
# 变量输入契约：
#   保持 tfvars 中的 list 结构不变，用 var.organization_units[0] / [1] 索引
#   即可，但由于每个位置显式写死，仅支持"业务实例数固定 = 代码中 module 块数"的
#   场景。新增/删除同类资源需同步增删对应 module 块。
# ==============================================================================

# ------------------------------------------------------------------------------
# 局部索引化：把 tfvars 中的 list 转成 map(key -> item)，便于按业务 key 引用
# ------------------------------------------------------------------------------
locals {
  ou_map          = { for ou in var.organization_units : ou.key => ou }
  account_map     = { for acc in var.organization_accounts : acc.account_name => acc }
  user_map        = { for u in var.cloud_identity_users : u.key => u }
  group_map       = { for g in var.cloud_identity_groups : g.key => g }
  ps_map          = { for ps in var.permission_sets : ps.key => ps }
  assignment_list = var.permission_set_assignments

  # 组织账号的 org_unit_id 解析函数：优先从 OU module 输出取，留空则挂 root
  # 由于 module 输出在下方按位置声明，这里定义解析函数需依赖静态 module 名
}

# ==============================================================================
# 1. 组织单元（OU）：串联
# ==============================================================================
module "ou_1" {
  source      = "./modules/organization-unit"
  parent_id   = var.root_parent_id
  name        = local.ou_map["ou_payment"].name
  description = local.ou_map["ou_payment"].description
}

module "ou_2" {
  source      = "./modules/organization-unit"
  parent_id   = var.root_parent_id
  name        = local.ou_map["ou_marketing"].name
  description = local.ou_map["ou_marketing"].description

  depends_on = [module.ou_1]
}

# ==============================================================================
# 2. 成员账号：串联，且等所有 OU 完成
# ==============================================================================
module "account_1" {
  source                   = "./modules/organization-account"
  account_name             = local.account_map["payment-app-260701b"].account_name
  show_name                = local.account_map["payment-app-260701b"].show_name
  description              = local.account_map["payment-app-260701b"].description
  allow_console            = local.account_map["payment-app-260701b"].allow_console
  verification_relation_id = local.account_map["payment-app-260701b"].verification_relation_id
  org_unit_id              = module.ou_1.org_unit_id
  tags                     = concat(local.account_map["payment-app-260701b"].tags, local.common_tags)

  depends_on = [module.ou_1, module.ou_2]
}

module "account_2" {
  source                   = "./modules/organization-account"
  account_name             = local.account_map["market-lab-260701b"].account_name
  show_name                = local.account_map["market-lab-260701b"].show_name
  description              = local.account_map["market-lab-260701b"].description
  allow_console            = local.account_map["market-lab-260701b"].allow_console
  verification_relation_id = local.account_map["market-lab-260701b"].verification_relation_id
  org_unit_id              = module.ou_2.org_unit_id
  tags                     = concat(local.account_map["market-lab-260701b"].tags, local.common_tags)

  depends_on = [module.account_1]
}

# ==============================================================================
# 3. 云身份中心用户：串联
# ==============================================================================
module "user_1" {
  source                  = "./modules/cloud-identity-user"
  user_name               = local.user_map["alice"].user_name
  display_name            = local.user_map["alice"].display_name
  description             = local.user_map["alice"].description
  email                   = local.user_map["alice"].email
  phone                   = local.user_map["alice"].phone
  password                = local.user_map["alice"].password
  password_reset_required = local.user_map["alice"].password_reset_required
}

module "user_2" {
  source                  = "./modules/cloud-identity-user"
  user_name               = local.user_map["bob"].user_name
  display_name            = local.user_map["bob"].display_name
  description             = local.user_map["bob"].description
  email                   = local.user_map["bob"].email
  phone                   = local.user_map["bob"].phone
  password                = local.user_map["bob"].password
  password_reset_required = local.user_map["bob"].password_reset_required

  depends_on = [module.user_1]
}

# ==============================================================================
# 4. 云身份中心用户组：串联，且等所有 users 完成
# ==============================================================================
module "group_1" {
  source          = "./modules/cloud-identity-group"
  group_name      = local.group_map["grp_netops"].group_name
  display_name    = local.group_map["grp_netops"].display_name
  description     = local.group_map["grp_netops"].description
  join_type       = local.group_map["grp_netops"].join_type
  member_user_ids = [module.user_1.user_id]

  depends_on = [module.user_1, module.user_2]
}

module "group_2" {
  source          = "./modules/cloud-identity-group"
  group_name      = local.group_map["grp_dev_readonly"].group_name
  display_name    = local.group_map["grp_dev_readonly"].display_name
  description     = local.group_map["grp_dev_readonly"].description
  join_type       = local.group_map["grp_dev_readonly"].join_type
  member_user_ids = [module.user_2.user_id]

  depends_on = [module.group_1]
}

# ==============================================================================
# 5. 访问权限集：串联
# ==============================================================================
module "ps_1" {
  source              = "./modules/permission-set"
  name                = local.ps_map["ps_network_admin"].name
  description         = local.ps_map["ps_network_admin"].description
  session_duration    = local.ps_map["ps_network_admin"].session_duration
  relay_state         = local.ps_map["ps_network_admin"].relay_state
  permission_policies = local.ps_map["ps_network_admin"].permission_policies
}

module "ps_2" {
  source              = "./modules/permission-set"
  name                = local.ps_map["ps_readonly"].name
  description         = local.ps_map["ps_readonly"].description
  session_duration    = local.ps_map["ps_readonly"].session_duration
  relay_state         = local.ps_map["ps_readonly"].relay_state
  permission_policies = local.ps_map["ps_readonly"].permission_policies

  depends_on = [module.ps_1]
}

# ==============================================================================
# 6. 访问授权（Assignment + Provisioning）：串联，且等所有上游完成
# ------------------------------------------------------------------------------
# 授权列表本工程共 3 条，按 assignment_list 的位置索引 [0][1][2] 逐个声明。
# ==============================================================================
module "assignment_1" {
  source            = "./modules/permission-set-assignment"
  permission_set_id = module.ps_1.permission_set_id
  principal_type    = local.assignment_list[0].principal_type
  principal_id      = module.group_1.group_id     # grp_netops
  target_id         = module.account_1.account_id # payment-app-260701b

  depends_on = [
    module.ps_1, module.ps_2,
    module.group_1, module.group_2,
    module.account_1, module.account_2,
  ]
}

module "assignment_2" {
  source            = "./modules/permission-set-assignment"
  permission_set_id = module.ps_1.permission_set_id
  principal_type    = local.assignment_list[1].principal_type
  principal_id      = module.group_1.group_id     # grp_netops
  target_id         = module.account_2.account_id # market-lab-260701b

  depends_on = [module.assignment_1]
}

module "assignment_3" {
  source            = "./modules/permission-set-assignment"
  permission_set_id = module.ps_2.permission_set_id
  principal_type    = local.assignment_list[2].principal_type
  principal_id      = module.group_2.group_id     # grp_dev_readonly
  target_id         = module.account_2.account_id # market-lab-260701b

  depends_on = [module.assignment_2]
}
