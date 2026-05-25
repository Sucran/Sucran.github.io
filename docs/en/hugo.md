# Hugo notes

- Configuration lives in `config/_default/`; content lives in `content/`.
- Multilingual files share the same basename with different suffixes, e.g. `article.en.md` / `article.zh.md`.
- Section list pages: `_index.en.md`, `_index.zh.md`.
- Preview: `hugo server`
- Production build: `hugo` → writes to `public/`

**Not source content:** `public/`, `resources/`, `.hugo_cache/`

**Shortcodes:** some posts use theme shortcodes (e.g. `{{< mermaid >}}`). Match existing posts in the same section when adding new ones.
