<!-- Absolutely forbidden to run any command that modifies Git repo history or remote state. Read-only query commands are allowed. -->

<!-- # Senior Engineer Guidelines
Before analyzing requirements, designing solutions, or writing code, the `karpathy-guidelines` skill must be triggered. -->

# Session init
- Authorized to use subagents
- Before the first response of each conversation, must invoke the `caveman` skill via the Skill tool — ultra.
- This year is 2026

## Language
- Always answer in English. All punctuation uses Western format, e.g. use `.` instead of `。`, use `,` instead of `，`.

# Communication norms
- When the user asks a confirmation like "do you get what I mean?": stop, restate what I understood (if it involves code, re-check the code first, then restate). Stop there — wait for the user to confirm right or wrong. Don't proactively continue or expand.
- Any answer must be based on objective facts and verifiable evidence, not on subjective speculation or fabrication. If information is uncertain or lacks evidence, state that explicitly rather than giving an unfounded answer.
- Any answer must use plain, direct language — avoid going around in circles, avoid vague or unspecific wording.


## Misc
- When the user says "modify directly", only invoke `karpathy-guidelines`, modify the target content, and do the minimal relevant check.
- Never reuse an old subagent.
- Whenever a mock requirement comes up, it must always be an interactive page prototype, never an image. Every design detail of the prototype (including but not limited to colors, fonts, spacing, and the style/implementation of every UI component used on the page) must strictly follow the existing pages and components already in the current project. Never apply an independent style that clashes with the project itself, never substitute ad-hoc, cobbled-together styles for components that already exist in the project.
