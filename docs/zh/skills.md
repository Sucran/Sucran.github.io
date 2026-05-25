# Skills 索引

**仅当**任务与描述匹配时，才读取对应 skill 的 `SKILL.md`。优先使用项目内 skill。

## 项目内 skills

| Skill | 路径 | 适用场景 |
|-------|------|----------|
| `adjust-markdown-format` | `.cursor/skills/adjust-markdown-format/SKILL.md` | Hugo 加粗/渲染修复（`）**`、引号加粗、LaTeX 格式） |
| `upload-markdown-images-to-oss` | `.cursor/skills/upload-markdown-images-to-oss/SKILL.md` | 通过 `scripts/` 将 Markdown 本地图片上传至阿里云 OSS |

## 共享 skills（工作区）

在 Cursor 环境中已安装时可用：

| Skill | 典型用途 |
|-------|----------|
| `create-rule` | 项目规则、`.cursor/rules/*.mdc`、更新 `AGENTS.md` |
| `create-skill` | 编写新的可复用 skill |
| `update-cursor-settings` | Cursor / VS Code 设置 |
| `context7-mcp` | 库 / 框架文档查询 |

其他共享 skill（Figma、Vercel、Supabase 等）可能位于用户 Cursor skills 缓存中 — 仅在与任务相关时加载。
