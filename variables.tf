# ==============================================================================
# 根模块变量定义
# ==============================================================================

variable "region" {
  type        = string
  description = "火山引擎区域，云身份中心建议使用 cn-beijing"
  default     = "cn-beijing"
}

variable "project" {
  type        = string
  description = "工程标识，会作为标签写入所有支持标签的资源"
  default     = "cloud-identity-iac"
}

variable "environment" {
  type        = string
  description = "环境标识：prod / staging / dev"
  default     = "prod"
}

# ------------------------------------------------------------------------------
# 企业组织：组织单元（OU）
# ------------------------------------------------------------------------------
variable "root_parent_id" {
  type        = string
  description = "顶层根组织单元 ID。留空或为占位符时，将通过 data source 自动取企业组织的 organization_id"
  default     = ""
}

variable "organization_units" {
  type = list(object({
    key         = string # OU 唯一逻辑 key，用于在 accounts 中引用
    name        = string
    description = string
  }))
  description = "企业组织单元列表（一级 OU，挂载在 root_parent_id 下）"
  default     = []
}

# ------------------------------------------------------------------------------
# 企业组织：成员账号
# ------------------------------------------------------------------------------
variable "organization_accounts" {
  type = list(object({
    account_name             = string
    show_name                = string
    description              = string
    org_unit_key             = string # 引用 organization_units.key，留空挂在 root
    allow_console            = number # 1 允许 / 2 不允许
    verification_relation_id = string # 多主体场景下的认证主体 ID，单主体留空
    tags = list(object({
      key   = string
      value = string
    }))
  }))
  description = "企业组织成员账号列表"
  default     = []
}

# ------------------------------------------------------------------------------
# 云身份中心：访问权限集
# ------------------------------------------------------------------------------
variable "permission_sets" {
  type = list(object({
    key              = string # 权限集唯一逻辑 key，用于在 assignments 中引用
    name             = string
    description      = string
    session_duration = number # 单位：秒，900-43200
    relay_state      = string # 登录后默认跳转地址，可留空
    permission_policies = list(object({
      permission_policy_name     = string # System 策略名 / Inline 时可留空
      permission_policy_type     = string # System | Inline
      permission_policy_document = string # Inline 时填写 JSON，System 留空
    }))
  }))
  description = "云身份中心访问权限集模板列表"
  default     = []
}

# ------------------------------------------------------------------------------
# 云身份中心：用户
# ------------------------------------------------------------------------------
variable "cloud_identity_users" {
  type = list(object({
    key                     = string # 用户唯一逻辑 key
    user_name               = string
    display_name            = string
    description             = string
    email                   = string
    phone                   = string
    password                = string # 留空则不设置初始密码
    password_reset_required = bool
  }))
  description = "云身份中心用户列表"
  default     = []
}

# ------------------------------------------------------------------------------
# 云身份中心：用户组
# ------------------------------------------------------------------------------
variable "cloud_identity_groups" {
  type = list(object({
    key          = string # 用户组唯一逻辑 key
    group_name   = string
    display_name = string
    description  = string
    join_type    = string       # Manual | Auto
    member_keys  = list(string) # 引用 cloud_identity_users.key
  }))
  description = "云身份中心用户组列表"
  default     = []
}

# ------------------------------------------------------------------------------
# 云身份中心：访问授权（permission_set + principal + target）
# ------------------------------------------------------------------------------
variable "permission_set_assignments" {
  type = list(object({
    permission_set_key = string # 引用 permission_sets.key
    principal_type     = string # User | Group
    principal_key      = string # principal_type=User 时引用 users.key；Group 时引用 groups.key
    target_account_key = string # 引用 organization_accounts.account_name；留空则使用 target_account_id
    target_account_id  = string # 直接指定外部已存在账号 ID（与 target_account_key 二选一）
  }))
  description = "访问授权列表：把权限集授予指定的用户/组，可访问指定的成员账号"
  default     = []
}
