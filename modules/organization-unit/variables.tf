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

variable "throttle_seconds" {
  type        = number
  description = "创建前节流等待秒数，避免 Cloud Control API 并发限制"
  default     = 0
}

variable "wait_for" {
  type        = any
  description = "链式串行的哨兵：等待前一个同类资源完成后再开始节流"
  default     = null
}
