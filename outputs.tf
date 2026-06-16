# ==============================================================================
# 根模块输出
# ==============================================================================

# ------ 企业组织 ------
output "organization_unit_ids" {
  description = "组织单元 ID 映射，key 为 OU 的逻辑 key"
  value       = { for k, ou in module.organization_units : k => ou.org_unit_id }
}

output "organization_account_ids" {
  description = "成员账号 ID 映射，key 为 account_name"
  value       = { for k, acc in module.organization_accounts : k => acc.account_id }
}

# ------ 云身份中心 ------
output "cloud_identity_user_ids" {
  description = "云身份中心用户 ID 映射，key 为用户逻辑 key"
  value       = { for k, u in module.cloud_identity_users : k => u.user_id }
}

output "cloud_identity_group_ids" {
  description = "云身份中心用户组 ID 映射，key 为用户组逻辑 key"
  value       = { for k, g in module.cloud_identity_groups : k => g.group_id }
}

output "permission_set_ids" {
  description = "权限集 ID 映射，key 为权限集逻辑 key"
  value       = { for k, ps in module.permission_sets : k => ps.permission_set_id }
}

# ------ 授权关系 ------
output "permission_set_assignment_status" {
  description = "授权部署状态映射，key 为授权组合字符串"
  value       = { for k, a in module.permission_set_assignments : k => a.provisioning_status }
}
