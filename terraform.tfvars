# ==============================================================================
# 火山引擎云身份中心 IaC 配置示例
# 场景：某集团公司在企业组织下管理 2 个业务单元（生产与沙盒），
#       并基于云身份中心实现网络运维、研发只读两类员工的多账号 SSO 授权。
#
# 使用前必读：
#   1. 必须由企业组织管理员账号执行（通过环境变量配置 AK/SK）
#   2. root_parent_id 需替换为你企业组织实际的根 OU id
#   3. password 字段在生产环境建议通过 -var 或 TF_VAR_ 环境变量传入，
#      避免明文写入 tfvars 文件
# ==============================================================================

region      = "cn-guilin-boe"
project     = "cloud-identity-demo"
environment = "prod"
# 企业组织根 OU ID（控制台 → 企业组织 → 组织结构 → 根节点 ID）
root_parent_id = "7352814720803651635"

# ------------------------------------------------------------------------------
# 组织结构：2 个一级 OU（Production / Sandbox）
# ------------------------------------------------------------------------------
organization_units = [
  {
    key         = "ou_prod"
    name        = "Production"
    description = "生产业务账号容器"
  },
  {
    key         = "ou_sandbox"
    name        = "Sandbox"
    description = "沙盒/测试账号容器"
  },
]

# ------------------------------------------------------------------------------
# 成员账号：每个 OU 各创建一个示例账号
# ------------------------------------------------------------------------------
organization_accounts = [
  {
    account_name             = "workload-prod-01"
    show_name                = "WorkloadProd01"
    description              = "生产业务负载账号"
    org_unit_key             = "ou_prod"
    allow_console            = 1
    verification_relation_id = ""
    tags = [
      { key = "BusinessUnit", value = "Workload" },
      { key = "CostCenter", value = "PROD-001" },
    ]
  },
  {
    account_name             = "sandbox-01"
    show_name                = "Sandbox01"
    description              = "研发沙盒账号"
    org_unit_key             = "ou_sandbox"
    allow_console            = 1
    verification_relation_id = ""
    tags = [
      { key = "BusinessUnit", value = "RnD" },
      { key = "CostCenter", value = "SANDBOX-001" },
    ]
  },
]

# ------------------------------------------------------------------------------
# 权限集：1) 网络运维管理员  2) 只读访问
# ------------------------------------------------------------------------------
permission_sets = [
  {
    key              = "ps_network_admin"
    name             = "NetworkOpsAdmin"
    description      = "网络运维管理员，可读写 VPC/CLB/EIP 等网络资源"
    session_duration = 3600
    relay_state      = "https://console.volcengine.com/vpc"
    permission_policies = [
      {
        permission_policy_name     = "VPCFullAccess"
        permission_policy_type     = "System"
        permission_policy_document = ""
      },
      {
        permission_policy_name     = "CLBFullAccess"
        permission_policy_type     = "System"
        permission_policy_document = ""
      },
    ]
  },
  {
    key              = "ps_readonly"
    name             = "ReadOnlyAccess"
    description      = "只读访问，研发查问题专用"
    session_duration = 7200
    relay_state      = ""
    permission_policies = [
      {
        permission_policy_name     = "ReadOnlyAccess"
        permission_policy_type     = "System"
        permission_policy_document = ""
      },
    ]
  },
]

# ------------------------------------------------------------------------------
# 云身份中心用户：2 名员工
# ------------------------------------------------------------------------------
cloud_identity_users = [
  {
    key                     = "alice"
    user_name               = "alice"
    display_name            = "Alice (NetOps)"
    description             = "网络运维工程师"
    email                   = "alice@example.com"
    phone                   = ""
    password                = "ChangeMe@2026"
    password_reset_required = true
  },
  {
    key                     = "bob"
    user_name               = "bob"
    display_name            = "Bob (Dev)"
    description             = "研发工程师"
    email                   = "bob@example.com"
    phone                   = ""
    password                = "ChangeMe@2026"
    password_reset_required = true
  },
]

# ------------------------------------------------------------------------------
# 云身份中心用户组：网络运维组、研发只读组
# ------------------------------------------------------------------------------
cloud_identity_groups = [
  {
    key          = "grp_netops"
    group_name   = "NetOpsTeam"
    display_name = "Network Operations Team"
    description  = "网络运维团队"
    join_type    = "Manual"
    member_keys  = ["alice"]
  },
  {
    key          = "grp_dev_readonly"
    group_name   = "DevReadOnly"
    display_name = "Developers ReadOnly"
    description  = "研发团队（只读访问）"
    join_type    = "Manual"
    member_keys  = ["bob"]
  },
]

# ------------------------------------------------------------------------------
# 访问授权：
#   1. NetOps 组对生产账号拥有网络管理员权限
#   2. NetOps 组对沙盒账号拥有网络管理员权限
#   3. DevReadOnly 组对沙盒账号拥有只读权限
# ------------------------------------------------------------------------------
permission_set_assignments = [
  {
    permission_set_key = "ps_network_admin"
    principal_type     = "Group"
    principal_key      = "grp_netops"
    target_account_key = "workload-prod-01"
    target_account_id  = ""
  },
  {
    permission_set_key = "ps_network_admin"
    principal_type     = "Group"
    principal_key      = "grp_netops"
    target_account_key = "sandbox-01"
    target_account_id  = ""
  },
  {
    permission_set_key = "ps_readonly"
    principal_type     = "Group"
    principal_key      = "grp_dev_readonly"
    target_account_key = "sandbox-01"
    target_account_id  = ""
  },
]
