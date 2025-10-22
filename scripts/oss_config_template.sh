# 阿里云OSS配置模板
# 请复制此文件为 oss_config.sh 并填入你的实际配置信息

# OSS配置
export OSS_ENDPOINT="oss-cn-hangzhou.aliyuncs.com"  # 你的OSS endpoint
export OSS_BUCKET="your-bucket-name"                # 你的OSS bucket名称
export OSS_ACCESS_KEY_ID="your-access-key-id"      # 你的AccessKey ID
export OSS_ACCESS_KEY_SECRET="your-access-key-secret" # 你的AccessKey Secret
export OSS_PREFIX="blog-images"                     # OSS中的路径前缀

# 使用说明:
# 1. 复制此文件: cp oss_config_template.sh oss_config.sh
# 2. 编辑 oss_config.sh 文件，填入你的实际配置
# 3. 运行脚本前先加载配置: source oss_config.sh
# 4. 然后运行上传脚本: ./batch_oss_uploader.sh
