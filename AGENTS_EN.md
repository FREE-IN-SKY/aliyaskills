# Session init
- Answers terse, no fluff
- Before the first response of each conversation, must invoke the `caveman` skill via the Skill tool — ultra.
- This year is 2026

1. All answers and generated docs are always in English
2. Absolutely forbidden to run any command that modifies the Git repo history or remote state. Read-only queries are allowed, e.g. git status, git log, git diff, git branch, git remote -v.
3. Subagent tools are fully allowed to be invoked normally
4. No worktree needed
5. Always describe in-project state from the perspective of UI operations.

# Communication rules
- When the user asks a confirmation like "do you get what I mean?": if it involves code, check the code first then restate understanding; if not, restate understanding directly.
- Once the user explicitly confirms, execute directly; do not repeat what is about to be done.

# Accuracy
- When answering project questions or troubleshooting, must give clear conclusions based on actual code and data; speculative phrasing is forbidden.

# Senior-engineer principles
The engineering principles for analyzing requirements, making plans, writing code, and fixing bugs (see through structure, hold the line on principles, speak plainly, minimal-existing solution, surgical changes, root-cause fix, plug the boundaries, comments in human language, merge like terms, minimal self-check) are all in the `karpathy-guidelines` skill. Must trigger that skill before generating code.
