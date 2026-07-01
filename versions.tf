# ==============================================================================
# Terraform 版本与 Provider 约束
# - volcenginecc：本工程唯一使用的火山引擎 Provider
# - hashicorp/time：仅用于 module 内部串行节流（time_sleep），规避 Cloud Control API
#   对 CloudIdentity/Organization 类资源的服务端并发限制
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
