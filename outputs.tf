# ==============================================================================
# 根模块输出
# 说明：静态 module 串联架构下，outputs 按业务 key 手动汇总。
# ==============================================================================

# ------ 企业组织 ------
output "organization_unit_ids" {
  description = "组织单元 ID 映射"
  value = {
    ou_payment   = module.ou_1.org_unit_id
    ou_marketing = module.ou_2.org_unit_id
  }
}

output "organization_account_ids" {
  description = "成员账号 ID 映射"
  value = {
    "payment-app-260701b" = module.account_1.account_id
    "market-lab-260701b"  = module.account_2.account_id
  }
}

# ------ 云身份中心 ------
output "cloud_identity_user_ids" {
  description = "云身份中心用户 ID 映射"
  value = {
    alice = module.user_1.user_id
    bob   = module.user_2.user_id
  }
}

output "cloud_identity_group_ids" {
  description = "云身份中心用户组 ID 映射"
  value = {
    grp_netops       = module.group_1.group_id
    grp_dev_readonly = module.group_2.group_id
  }
}

output "permission_set_ids" {
  description = "权限集 ID 映射"
  value = {
    ps_network_admin = module.ps_1.permission_set_id
    ps_readonly      = module.ps_2.permission_set_id
  }
}

# ------ 授权关系 ------
output "permission_set_assignment_status" {
  description = "授权部署状态映射"
  value = {
    "ps_network_admin|Group|grp_netops|payment-app-260701b" = module.assignment_1.provisioning_status
    "ps_network_admin|Group|grp_netops|market-lab-260701b"  = module.assignment_2.provisioning_status
    "ps_readonly|Group|grp_dev_readonly|market-lab-260701b" = module.assignment_3.provisioning_status
  }
}
