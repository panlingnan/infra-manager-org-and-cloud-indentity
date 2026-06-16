variable "permission_set_id" {
  type        = string
  description = "权限集 ID"
}

variable "principal_type" {
  type        = string
  description = "授权对象类型：User 或 Group"

  validation {
    condition     = contains(["User", "Group"], var.principal_type)
    error_message = "principal_type 必须是 User 或 Group"
  }
}

variable "principal_id" {
  type        = string
  description = "授权对象 ID（User ID 或 Group ID）"
}

variable "target_id" {
  type        = string
  description = "目标账号 ID（火山引擎账号 ID）"
}
