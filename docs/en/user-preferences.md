# User preferences

Constraints the repo owner has asked agents to follow:

- Do **not** run Docker image build commands in the background.
- Do **not** edit Cursor `mcp.json` without explicit permission.
- Use **Context7 MCP** at the start of coding work unless the user specifies a particular framework version.
- Place agent-generated explanation-only markdown under `.cursor/docs/` — do not commit those files.
- Only create git commits when the user explicitly asks.
