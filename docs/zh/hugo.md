# Hugo 说明

- 配置在 `config/_default/`，正文在 `content/`。
- 多语言文件共用 basename、不同后缀，例如 `article.en.md` / `article.zh.md`。
- 分区列表页：`_index.en.md`、`_index.zh.md`。
- 预览：`hugo server`
- 生产构建：`hugo` → 输出到 `public/`

**非源内容：** `public/`、`resources/`、`.hugo_cache/`

**Shortcodes：** 部分文章使用主题 shortcode（如 `{{< mermaid >}}`）。在同一分区新增内容时，参考已有文章的写法。
