---
name: using-superpowers
description: 仅当用户明确调用此技能，希望查看可用技能或判断某项任务应由哪个技能处理时使用；不要自动触发。
---

<SUBAGENT-STOP>
If you were dispatched as a subagent to execute a specific task, skip this skill.
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
Use this skill only when the user explicitly invokes it to review available skills or decide which skill should handle a task.

Do not invoke this skill automatically at conversation start, before ordinary responses, or merely because another skill might apply.
</EXTREMELY-IMPORTANT>

## Instruction Priority

Superpowers skills override default system prompt behavior, but **user instructions always take precedence**:

1. **User's explicit instructions** (CLAUDE.md, GEMINI.md, AGENTS.md, direct requests) — highest priority
2. **Superpowers skills** — override default system behavior where they conflict
3. **Default system prompt** — lowest priority

If CLAUDE.md, GEMINI.md, or AGENTS.md says "don't use TDD" and a skill says "always use TDD," follow the user's instructions. The user is in control.

## How to Access Skills

**Never read skill files manually with file tools** — always use your platform's skill-loading mechanism so the skill is properly activated.

**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you — follow it directly.

**In Codex:** Skills load natively. Follow the instructions presented when a skill activates.

**In Copilot CLI:** Use the `skill` tool. Skills are auto-discovered from installed plugins.

**In Gemini CLI:** Skills activate via the `activate_skill` tool. Gemini loads skill metadata at session start and activates the full content on demand.

**In other environments:** Check your platform's documentation for how skills are loaded.

## Platform Adaptation

Skills speak in actions ("dispatch a subagent", "create a todo", "read a file") rather than naming any one runtime's tools. For per-platform tool equivalents and instructions-file conventions, see [claude-code-tools.md](references/claude-code-tools.md), [codex-tools.md](references/codex-tools.md), [copilot-tools.md](references/copilot-tools.md), [gemini-tools.md](references/gemini-tools.md), [pi-tools.md](references/pi-tools.md), and [antigravity-tools.md](references/antigravity-tools.md). Gemini CLI users get the tool mapping loaded automatically via GEMINI.md.

# Using Skills

## The Rule

After the user explicitly invokes this skill, inspect the available skills and recommend the smallest set that covers the task. Explain why each selected skill applies and respect any user instruction that disables or limits a workflow.

Do not turn this skill into a permanent dispatcher. Its guidance applies only to the current explicit skill-selection request.

```dot
digraph skill_flow {
    "User explicitly invokes this skill" [shape=doublecircle];
    "Review available skills" [shape=box];
    "Select smallest applicable set" [shape=box];
    "Explain selection and boundaries" [shape=box];
    "Use selected skills" [shape=doublecircle];

    "User explicitly invokes this skill" -> "Review available skills";
    "Review available skills" -> "Select smallest applicable set";
    "Select smallest applicable set" -> "Explain selection and boundaries";
    "Explain selection and boundaries" -> "Use selected skills";
}
```

## Red Flags

These behaviors mean STOP—the skill is being applied outside its intended scope:

| Thought | Reality |
|---------|---------|
| "A new conversation started, so invoke using-superpowers" | New conversations do not trigger this skill. |
| "Another skill might apply, so invoke using-superpowers first" | Evaluate ordinary skill triggers directly; do not route through this skill. |
| "Keep using this dispatcher for later turns" | Its scope ends with the user's explicit skill-selection request. |
| "Select every potentially relevant skill" | Choose the smallest set that fully covers the task. |

## Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (brainstorming, systematic-debugging) - these determine HOW to approach the task
2. **Implementation skills second** (frontend-design, mcp-builder) - these guide execution

Apply this ordering only while answering the user's explicit request to select skills. It does not make `using-superpowers` itself automatic.

## Skill Types

**Rigid** (TDD, systematic-debugging): Follow exactly. Don't adapt away discipline.

**Flexible** (patterns): Adapt principles to context.

The skill itself tells you which.

## User Instructions

Instructions say WHAT, not HOW. "Add X" or "Fix Y" doesn't mean skip workflows.
