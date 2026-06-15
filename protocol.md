# Autonomous Learning Protocol

## For AI Coding Agents Using wafle-anamnesis

This protocol is MANDATORY for any agent running with wafle-anamnesis.
It creates the autonomous memory loop.

---

### PHASE 1: SESSION START — Continuity Load (lightweight)

```powershell
powershell -File src/engram-context.ps1 -Project <your-project>
```

Loads only:
- Continuity state (last session, pending tasks)
- Cloud/autosync status

Does NOT load past errors. That is on-demand only.

### PHASE 2: DURING WORK — On-Demand Memory Check

Only search when actively debugging or making decisions:

```
engram search mcp-error: --project <project> --type bugfix
engram search <decision-topic> --project <project> --type decision
```

If MCP tools are unavailable, use Engram CLI directly:

```powershell
/path/to/engram.exe search <query> --project <project>
```

Do NOT search when there is no active error or decision pending.

### PHASE 3: AFTER EACH TASK — Persist Knowledge

**Automatic** (zero effort):
- MCP server errors tracked by `mcp-launcher.ps1` → auto-saves via:
  ```
  engram save <title> <content> --type bugfix --project <project> --scope project
  ```

**Manual** (agent must call when relevant):
- `engram save <title> <details> --type decision --scope project` for architecture choices
- `engram save <title> <details> --type config --scope project` for config changes
- `engram save <title> <details> --type discovery --scope project` for non-obvious findings

Use the same **content** format as Engram: `**What**: ... | **Why**: ... | **Where**: ... | **Learned**: ...`

Fallback when MCP is disconnected:
```powershell
engram save <title> <content> --type <type> --project <project> --scope project
```

### PHASE 4: SESSION CLOSE — Summarize

```powershell
mem_session_summary --project <project>
```

Fallback when MCP is disconnected:
```powershell
engram save "session-summary: <date>" "<full summary>" --type session_summary --project <project>
```

Also write `_session-summary-<date>.md` as local backup.

---

## Error Patterns (for search)

| Pattern | When | Saved By |
|---|---|---|
| `mcp-error: <name> exited with <code>` | MCP crashes | Auto (launcher) |
| `bugfix: <description>` | Root cause found | Agent (mem_save) |
| `decision: <topic>` | Architecture choice | Agent (mem_save) |
| `discovery: <finding>` | Non-obvious insight | Agent (mem_save) |
| `config: <change>` | Config/environment fix | Agent (mem_save) |
| `session_summary` | End of session | Agent (mem_session_summary) |

## Minimal Agent Instructions

```
You have access to wafle-anamnesis autonomous memory.
- At session start: run engram-context.ps1 (continuity only, ~5 lines)
- When debugging: search Engram for similar errors first
- After each task: save decisions to Engram
- At session end: save session summary
```
