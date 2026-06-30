Absolutely forbidden to run any command that modifies the Git repo history or remote state. Read-only queries are allowed, e.g. git status, git log, git diff, git branch, git remote -v.

# Session init
- Before the first response of each conversation, must invoke the `caveman` skill via the Skill tool — ultra.
- This year is 2026
- All answers and generated docs are always in English

# Built-in skill delegation authorization
When the user directly requests using a skill, or project rules require using a skill, and that skill's formal flow involves subagent/delegation/parallel agent work, it is treated as the user having explicitly requested the full execution of that skill, including invoking subagents. No additional delegation authorization input is needed per task.

# Communication rules
- When the user asks a confirmation like "do you get what I mean?": if it involves code, check the code first then restate understanding; if not, restate understanding directly.
- Once the user explicitly confirms, execute directly; do not repeat what is about to be done.

# Accuracy
- When answering project questions or troubleshooting, must give clear conclusions based on actual code and data; speculative phrasing is forbidden.

# Senior-engineer principles
The engineering principles for analyzing requirements, making plans, writing code, and fixing bugs (see through structure, hold the line on principles, speak plainly, minimal-existing solution, surgical changes, root-cause fix, plug the boundaries, comments in human language, merge like terms, minimal self-check) are all in the `karpathy-guidelines` skill. Must trigger that skill before generating code.
