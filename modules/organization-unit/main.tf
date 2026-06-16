# ==============================================================================
# 模块：organization-unit
# 功能：火山引擎企业组织单元（OU）封装
# 描述：单个 OU 的创建。多个 OU 由根模块 for_each 调用本模块批量管理，
#       并支持通过 parent_id 构建多层级组织树。
# 典型场景：
#   - 集团多业务线划分（如 BU-A / BU-B）
#   - 测试环境与生产环境隔离（如 prod / staging）
# ==============================================================================
resource "volcenginecc_organization_unit" "this" {
  parent_id   = var.parent_id
  name        = var.name
  description = var.description
}
