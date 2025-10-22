# 脚本工具集

本目录包含博客图片处理的通用脚本工具集。

## 核心脚本

- `common.sh` - 通用函数库
- `image_processor.sh` - 图片处理脚本
- `oss_uploader.sh` - OSS上传脚本
- `batch_processor.sh` - 批量处理脚本

## 配置文件

- `oss_config.sh` - OSS配置文件（包含敏感信息，已加入.gitignore）
- `oss_config_template.sh` - OSS配置模板

## 详细文档

详细的说明文档请查看：`.cursor/docs/scripts_README.md`

## 快速开始

1. 配置OSS：`cp oss_config_template.sh oss_config.sh` 并编辑
2. 处理图片：`./image_processor.sh content/article.md`
3. 上传OSS：`./oss_uploader.sh static/img/`
4. 批量处理：`./batch_processor.sh full-pipeline "content/*.md"`