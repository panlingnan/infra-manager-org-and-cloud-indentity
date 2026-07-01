# ==============================================================================
# 模块：organization-unit
# 功能：火山引擎企业组织单元（OU）封装
# ==============================================================================
resource "volcenginecc_organization_unit" "this" {
  parent_id   = var.parent_id
  name        = var.name
  description = var.description
}
