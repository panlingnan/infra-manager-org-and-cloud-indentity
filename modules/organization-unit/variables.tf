variable "parent_id" {
  type        = string
  description = "父级单元 ID。顶级 OU 传入 root parent id；子 OU 传入上层 OU 的 org_unit_id"
}

variable "name" {
  type        = string
  description = "组织单元名称"
}

variable "description" {
  type        = string
  description = "组织单元描述"
  default     = ""
}
