# ==============================================================================
# Terraform 版本与 Provider 约束
# - volcenginecc：本工程唯一使用的火山引擎 Provider
# - hashicorp/time：仅用于 module 内部 time_sleep 节流
# ==============================================================================
terraform {
  required_version = ">= 1.0.7"

  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "~> 0.0.40"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}
