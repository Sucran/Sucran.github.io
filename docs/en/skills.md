# Skills index

Read a skill's `SKILL.md` **only when** the task matches its description. Prefer project-local skills first.

## Project-local skills

| Skill | Path | Use when |
|-------|------|----------|
| `adjust-markdown-format` | `.cursor/skills/adjust-markdown-format/SKILL.md` | Hugo bold/rendering fixes (`）**`, quoted bold, LaTeX formatting) |
| `upload-markdown-images-to-oss` | `.cursor/skills/upload-markdown-images-to-oss/SKILL.md` | Upload markdown local images to Aliyun OSS via `scripts/` |

## Shared skills (workspace)

Available when installed in the Cursor environment:

| Skill | Typical use |
|-------|-------------|
| `create-rule` | Project rules, `.cursor/rules/*.mdc`, updating `AGENTS.md` |
| `create-skill` | Authoring new reusable skills |
| `update-cursor-settings` | Cursor / VS Code settings |
| `context7-mcp` | Library / framework documentation lookup |

Other shared skills (Figma, Vercel, Supabase, etc.) may also be present under the user's Cursor skills cache — load only if the task requires that domain.
