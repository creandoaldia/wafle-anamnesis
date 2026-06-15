
```
﻿██╮    ██╮  █████╮  ███████╮██╮     ███████╮
██│    ██│ ██╭──██╮ ██╭────╯██│     ██╭────╯
██│ █╮ ██│ ███████│ █████╮  ██│     █████╮  
██│███╮██│ ██╭──██│ ██╭──╯  ██│     ██╭──╯  
╰███╭███╭╯ ██│  ██│ ██│     ███████╮███████╮
 ╰──╯╰──╯  ╰─╯  ╰─╯ ╰─╯     ╰──────╯╰──────╯
```

<video src="https://raw.githubusercontent.com/creandoaldia/wafle-anamnesis/main/assets/wafle-anamnesis.mp4" controls width="100%"></video>

*Explainer video (40s): the full autonomous memory pipeline with benchmarks and knowledge graph.*

# wafle-anamnesis

**Autonomous Memory Echo System for AI Coding Agents**

Error events echo across sessions. Past fixes prevent future mistakes. The agent learns and evolves without humans in the loop.

## The Problem

AI coding agents (like OpenCode, Claude Code, Gemini CLI) have **zero cross-session memory** by default. Every session starts blank:
- Errors fixed yesterday? Gone.
- Architecture decisions? Forgotten.
- Config workarounds? Lost.

Humans bridge the gap manually: "remember that thing we fixed last week?" If the human doesn't ask, the agent repeats mistakes.

## The Solution

`wafle-anamnesis` closes the loop with **3 autonomous components**:

```
ERROR → mcp-launcher.ps1 → engram save CLI → .engram/ DB → cloud sync
                                                    ↓
NEXT SESSION → engram-context.ps1 → loads past errors → agent knows
                                                    ↓
                                   agent prevents same error
```

### 1. `src/mcp-launcher.ps1` — Auto-capture on error

- Wraps any MCP server process
- Kills only **true orphans** (parent dead or not an mcp-launcher)
- On non-zero exit: auto-saves error details to Engram via CLI
- No MCP connection needed — writes directly to local DB

### 2. `src/engram-context.ps1` — Continuity loader (lightweight)

Run at session start. Loads only (~5 lines of output):
- Continuity metadata (last session, pending tasks)
- Cloud sync status

Does NOT load past errors — that is on-demand when debugging.

### 3. Agent Protocol — Autonomous Learning Loop

The agent follows this loop (documented in `protocol.md`):

1. **SESSION START** — run `engram-context.ps1` (continuity only)
2. **DURING WORK** — search Engram for past errors ONLY when debugging
3. **AFTER EACH TASK** — auto-save via launcher, manual `engram save` for decisions
4. **SESSION CLOSE** — `engram session-summary` to cloud

## Requirements

- **Engram** v1.16+ (`engram serve` daemon running on port 7437)
- **PowerShell** 5.1+ (Windows)
- An Engram cloud endpoint (optional, for cross-machine sync)

## Installation

### 1. Install Engram

```bash
go install github.com/Gentleman-Programming/engram/cmd/engram@latest
engram serve &
```

Or download from [releases](https://github.com/Gentleman-Programming/engram/releases).

### 2. Add to your project

**For OpenCode:** Add to `opencode.json`:

```json
{
  "mcp": {
    "my-server": {
      "command": [
        "powershell", "-NoLogo", "-NoProfile", "-File",
        "tools/mcp-launcher.ps1",
        "-ProcessName", "my-server",
        "-Command", "my-server --some-flag"
      ]
    }
  }
}
```

**For other agents:** Wrap any MCP command with the launcher.

### 3. Add the context loader to your agent config

Add to your agent's instructions/config the rule:

```
On session start, run: powershell -File tools/engram-context.ps1
```

## The Autonomous Loop in Detail

```
                    ┌─────────────────────────────────┐
                    │      AGENT SESSION               │
                    │                                  │
                    │  engram-context.ps1 (continuity) │
                    │    ↓                             │
                    │  Agent works normally...         │
                    │                                  │
                    │  → Error occurs?                 │
                    │    ↓                             │
                    │  mcp-launcher.ps1 auto-saves     │
                    │  to Engram (zero agent effort)   │
                    │                                  │
                    │  → Debugging?                    │
                    │    ↓                             │
                    │  Agent searches Engram for       │
                    │  similar past errors (on-demand) │
                    │                                  │
                    │  → Fixed?                        │
                    │    ↓                             │
                    │  Agent saves root cause          │
                    │  to Engram (mem_save)            │
                    └─────────────────────────────────┘
```

## File Structure

```
wafle-anamnesis/
├── README.md               ← this file
├── protocol.md             ← autonomous learning protocol for agents
├── assets/
│   └── wafle-logo.txt      ← WAFLE brand logo
├── src/
│   ├── mcp-launcher.ps1    ← MCP wrapper with error auto-capture
│   └── engram-context.ps1  ← Pre-flight context loader
└── opencode-integration.json  ← example OpenCode config
```

## Why "Echo"?

Errors echo across sessions. The system doesn't forget. What you fixed yesterday is known today — not because a human remembered, but because the machine persisted it. The echo carries knowledge forward.


![Knowledge Graph](https://raw.githubusercontent.com/creandoaldia/wafle-anamnesis/main/assets/captura_anamnesis.png)

*Knowledge graph: 42 bugfixes organized across 7 topic clusters, auto-saved and ready for on-demand search.*

## License

MIT - See [LICENSE](LICENSE) file for details.
