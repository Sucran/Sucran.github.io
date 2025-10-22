# 阿里云OSS图片批量上传工具

这是一个用于批量上传本地图片到阿里云OSS并自动更新markdown链接的Shell脚本工具。

## 文件说明

- `batch_oss_uploader.sh` - 主脚本文件
- `oss_config_template.sh` - OSS配置模板
- `test_oss_uploader.sh` - 测试脚本
- `.cursor/docs/oss_uploader_usage.md` - 详细使用说明

## 快速开始

1. **安装依赖**
   ```bash
   # 下载并安装ossutil
   curl -o ossutil https://gosspublic.alicdn.com/ossutil/1.7.19/ossutil
   chmod 755 ossutil
   sudo mv ossutil /usr/local/bin/
   ```

2. **配置OSS参数**
   ```bash
   # 复制配置模板
   cp oss_config_template.sh oss_config.sh
   
   # 编辑配置文件，填入你的OSS信息
   vim oss_config.sh
   ```

3. **测试工具**
   ```bash
   # 运行测试脚本
   ./test_oss_uploader.sh
   
   # 试运行模式（推荐先运行）
   ./batch_oss_uploader.sh --dry-run
   ```

4. **正式使用**
   ```bash
   # 处理所有markdown文件
   ./batch_oss_uploader.sh
   
   # 处理单个文件
   ./batch_oss_uploader.sh content/cources/cs231n/lec_1.zh.md
   ```

## 主要功能

- 🚀 批量处理多个markdown文件
- 🔄 自动上传图片到阿里云OSS
- 🔗 自动更新markdown中的图片链接
- 🛡️ 支持试运行模式，安全预览
- 📁 支持指定单个文件或整个目录
- ⚙️ 支持配置文件管理
- 🎨 彩色输出，清晰显示处理状态

## 工作原理

1. 扫描markdown文件中的本地图片链接（如 `/img/xxx.png`）
2. 将对应的本地图片文件上传到阿里云OSS
3. 将markdown中的本地路径替换为OSS CDN地址
4. 自动备份原文件，失败时自动恢复

## 示例

**处理前：**
```markdown
![图片说明](/img/cs231n/lec1_image1.png)
```

**处理后：**
```markdown
![图片说明](https://your-bucket.oss-cn-hangzhou.aliyuncs.com/blog-images/img/cs231n/lec1_image1.png)
```

## 安全特性

- ✅ 试运行模式：可以先预览所有操作
- ✅ 自动备份：处理前自动备份原文件
- ✅ 错误恢复：失败时自动恢复备份
- ✅ 依赖检查：运行前检查必要工具

## 注意事项

1. **首次使用建议先运行试运行模式**
2. **确保OSS配置正确**
3. **备份重要文件**
4. **确保网络连接稳定**

详细使用说明请查看：`.cursor/docs/oss_uploader_usage.md`
