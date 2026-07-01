variable "parent_id" {
  type        = string
  description = "父级单元 ID"
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
