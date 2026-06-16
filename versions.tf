# ==============================================================================
# Terraform 版本与 Provider 约束
# 仅使用火山引擎 volcenginecc Provider
# ==============================================================================
terraform {
  required_version = ">= 1.0.7"

  required_providers {
    volcenginecc = {
      source  = "volcengine/volcenginecc"
      version = "~> 0.0.40"
    }
  }
}
