output "org_unit_id" {
  description = "组织单元 ID，用于子 OU 或成员账号引用"
  value       = volcenginecc_organization_unit.this.org_unit_id
}

output "id" {
  description = "Terraform 资源 ID"
  value       = volcenginecc_organization_unit.this.id
}
