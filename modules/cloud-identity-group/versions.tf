terraform {
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
