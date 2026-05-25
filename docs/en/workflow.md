# Suggested agent workflow

1. Read root [`AGENTS.md`](../../AGENTS.md) — pick the relevant doc from the index table.
2. Load **only** the matching file(s) under `docs/en/` (or `docs/zh/` for Chinese tasks).
3. If the task touches Hugo content, bilingual menus, or `scripts/`, read [`conventions.md`](conventions.md) and [`structure.md`](structure.md).
4. If a project-local skill applies, read its `SKILL.md` before editing.
5. After changes, run `hugo` to verify the site builds when content or config changed.
6. Keep ephemeral notes in `.cursor/docs/`, not in `content/` or committed paths.
