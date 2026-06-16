output "assignment_id" {
  description = "授权资源 ID"
  value       = volcenginecc_cloudidentity_permission_set_assignment.this.id
}

output "provisioning_status" {
  description = "权限集部署状态"
  value       = volcenginecc_cloudidentity_permission_set_provisioning.this.provisioning_status
}
