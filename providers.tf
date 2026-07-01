# ==============================================================================
# 火山引擎 Provider 配置
# 推荐通过环境变量提供凭证（避免 AK/SK 硬编码到代码仓库）：
#   export VOLCENGINE_ACCESS_KEY="your_ak"
#   export VOLCENGINE_SECRET_KEY="your_sk"
#   export VOLCENGINE_REGION="cn-beijing"
#
# 如需切换内部测试 endpoint（如 cn-guilin-boe），通过环境变量传入：
#   export VOLCENGINE_ENDPOINT="cloudcontrol.cn-beijing.volcengineapi.com"
#
# 注意：云身份中心是企业组织管理员账号下的全局服务，必须使用管理员账号 AK/SK 执行。
# ==============================================================================
provider "volcenginecc" {
  # endpoints = {
  #   cloudcontrolapi = "open.stable.volcengineapi-test.com"
  # }
  region = "cn-beijing"
}
