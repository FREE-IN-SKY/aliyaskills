
<!-- The following two comment blocks may be placed under the project's AGENTS.md or CLAUDE.md -->
<!-- Absolutely forbidden to run any command that modifies Git repo history or remote state. Read-only query commands are allowed. -->

<!-- # Senior Engineer Guidelines
Before analyzing requirements, designing solutions, or writing code, the `karpathy-guidelines` skill must be triggered. -->

<!-- The following section may be placed under the global AGENTS.md or CLAUDE.md -->
# Session init
- Authorized to use subagents
- Before the first response of each conversation, must invoke the `caveman` skill via the Skill tool — ultra.
- This year is 2026


## Language
<!-- {LANGUAGE} is a placeholder — replace it with the actual target language when applying this to a real project, e.g. "Chinese" / "English" / "Japanese" -->
- Always answer in {LANGUAGE}. All punctuation uses Western format, e.g. use `.` instead of `。`, use `,` instead of `，`.

# Communication norms
- When the user asks a confirmation like "do you get what I mean?": stop, restate what I understood (if it involves code, re-check the code first, then restate). Stop there — wait for the user to confirm right or wrong. Don't proactively continue or expand.

## Misc
- When the user says "modify directly", only invoke `karpathy-guidelines`, modify the target content, and do the minimal relevant check.
- Never reuse an old subagent.
- When the user signals intent to start a task, decide independently whether a subagent is needed. Small, single-step, or non-decomposable tasks are done directly by the main agent — no subagent. Delegate only when the task contains independently handleable subtasks. When delegating: simple mechanical subtasks go to Luna, routine implementation/investigation subtasks go to Terra, complex architecture or high-risk subtasks go to Sol. The main agent always does the final review and consolidation.
- Whenever a mock requirement comes up, it must always be an interactive page prototype, never an image. Every design detail of the prototype (including but not limited to colors, fonts, spacing, and the style/implementation of every UI component used on the page) must strictly follow the existing pages and components already in the current project. Never apply an independent style that clashes with the project itself, never substitute ad-hoc, cobbled-together styles for components that already exist in the project.
- Any answer must be based on objective facts and verifiable evidence, not on subjective speculation or fabrication. If information is uncertain or lacks evidence, state that explicitly rather than giving an unfounded answer.
- Any answer must use plain, direct language — avoid going around in circles, avoid vague or unspecific wording.
- Before modifying a file, must report to the user first; the user decides whether to proceed.
