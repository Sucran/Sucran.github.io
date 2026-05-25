# 建议的 agent 工作流

1. 阅读根目录 [`AGENTS_zh.md`](../../AGENTS_zh.md) — 从索引表选择相关文档。
2. **仅**加载 `docs/zh/`（或英文任务时 `docs/en/`）下匹配的文件。
3. 若涉及 Hugo 内容、双语菜单或 `scripts/`，阅读 [`conventions.md`](conventions.md) 与 [`structure.md`](structure.md)。
4. 若命中项目内 skill，编辑前先读其 `SKILL.md`。
5. 修改内容或配置后，运行 `hugo` 验证站点能否构建。
6. 临时说明放在 `.cursor/docs/`，不要写入 `content/` 或应提交的路径。
