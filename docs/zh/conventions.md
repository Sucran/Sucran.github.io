# 编辑约定

- 中英文内容分文件维护：`*.en.md` 与 `*.zh.md`。
- 新增或修改导航分区时，**同时**更新 `config/_default/menus.en.toml` 与 `config/_default/menus.zh.toml`。
- 尽量保持 `content/` 下现有分区命名与内容摆放方式。
- 分区首页使用 `_index.<lang>.md`。
- 仅在内容可发布时将 `draft` 设为 `false`。
- Hugo Markdown 渲染问题（如 `）**` 加粗失效）见 [`skills.md`](skills.md) 中的 `adjust-markdown-format`。
- 本地图片需上传 CDN 时，见 [`skills.md`](skills.md) 中的 `upload-markdown-images-to-oss`。

**不要**把 agent 生成的说明性 Markdown 放在 `content/` 或仓库根目录。临时说明放在 `.cursor/docs/`（gitignore）。
