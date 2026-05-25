# 用户偏好

仓库主希望 agent 遵守的约束：

- **不要**在后台执行 Docker 镜像构建命令。
- **不要**在未获明确许可时修改 Cursor 的 `mcp.json`。
- 开始编码时优先使用 **Context7 MCP**，除非用户指定了特定框架版本。
- agent 生成的纯说明性 Markdown 放在 `.cursor/docs/`，不要提交到 git。
- 仅在用户明确要求时创建 git commit。
