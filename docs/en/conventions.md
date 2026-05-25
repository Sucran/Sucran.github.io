# Editing conventions

- Keep English and Chinese content in separate files: `*.en.md` and `*.zh.md`.
- When adding or changing navigational sections, update **both** `config/_default/menus.en.toml` and `config/_default/menus.zh.toml`.
- Preserve existing section naming and content placement under `content/`.
- Section landing pages use `_index.<lang>.md`.
- Set `draft: false` only when content is ready to publish.
- For Hugo markdown rendering issues (e.g. bold after `）**`), see skill `adjust-markdown-format` in [`skills.md`](skills.md).
- For local images that should be served from CDN, see skill `upload-markdown-images-to-oss` in [`skills.md`](skills.md).

**Do not** put agent-generated explanation markdown in `content/` or the repo root. Use `.cursor/docs/` for ephemeral notes (gitignored).
