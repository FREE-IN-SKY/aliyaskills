---
name: systematic-debugging-custom
description: Use when encountering any bug, test failure, build failure, performance issue, or unexpected behavior to investigate and report the root cause only; do not automatically modify code
---

# Systematic Debugging

## Purpose

Use this skill to diagnose technical problems with evidence and return a root-cause report to the user.

Default behavior is read-only investigation. Do not edit source files, tests, configuration, scripts, lockfiles, generated files, or docs while using this skill unless the user explicitly gives a separate follow-up instruction to implement a fix.

## Iron Law

```
ROOT CAUSE REPORT ONLY. NO AUTOMATIC CODE MODIFICATIONS.
```

Do not propose or apply a patch before the root cause is proven. Do not treat symptoms as root causes.

## When to Use

Use for:
- Test failures
- Production bugs
- Unexpected behavior
- Build failures
- Performance regressions
- Integration failures
- Flaky or timing-dependent behavior

Use this especially when a quick fix seems obvious, previous fixes failed, or the system crosses multiple components.

## Workflow

Complete each phase in order.

### Phase 1: Evidence Collection

1. **Read the exact failure**
   - Read full error messages, stack traces, warnings, paths, line numbers, and error codes.
   - Do not summarize the failure until the relevant details are captured.

2. **Reproduce or bound the issue**
   - Run the smallest existing command that demonstrates the issue.
   - Record whether it reproduces consistently.
   - If it is not reproducible, gather more logs or state before forming conclusions.

3. **Check recent change surface**
   - Inspect diffs, recent commits, dependency changes, config changes, and environment differences.
   - Treat “what changed?” as evidence, not as proof.

4. **Trace data and control flow**
   - Follow the bad value, failing state, or unexpected branch backward to its origin.
   - For deep call stacks, read `root-cause-tracing.md` in this skill directory only if needed.

5. **Map component boundaries**
   - For multi-component systems, identify where data/config/state enters and exits each layer.
   - Prefer existing logs, commands, tests, and inspection.
   - If proving the boundary requires adding instrumentation or creating a reproduction file, ask the user before modifying files.

### Phase 2: Pattern Comparison

1. **Find working examples**
   - Locate similar working code, tests, configs, or workflows in the same codebase.

2. **Compare exact differences**
   - List meaningful differences between the working path and failing path.
   - Do not dismiss small differences without evidence.

3. **Identify assumptions**
   - Capture required dependencies, ordering, configuration, state, timing, and invariants.

### Phase 3: Hypothesis Testing

1. **State one hypothesis**
   - Use the form: “I think X is the root cause because Y evidence shows Z.”

2. **Test without editing code**
   - Use read-only commands, existing tests, logs, traces, config inspection, runtime observation, or targeted reproduction using existing files.
   - Change one variable at a time when running commands or altering runtime inputs.
   - Do not patch code, add tests, or refactor as part of the test.

3. **Accept or reject the hypothesis**
   - If evidence confirms it, move to the report.
   - If evidence disproves it, form a new hypothesis from the new evidence.
   - If evidence is insufficient, say what is missing instead of guessing.

### Phase 4: Root-Cause Report

Return a concise report with:

- **Root cause:** the original trigger and failing component.
- **Evidence:** commands, outputs, stack frames, files, functions, line numbers, config values, or commits that prove it.
- **Why the symptom happens:** the causal chain from root trigger to observed failure.
- **Confidence:** confirmed, likely, or unresolved, with reason.
- **Fix direction:** the smallest likely remediation and validation path, described only as a recommendation.
- **No changes made:** explicitly state that no files were modified during this skill run.

If the root cause is not proven, report:
- What is known.
- What remains unknown.
- What evidence is needed next.
- Why a conclusion would be premature.

## Hard Constraints

- Do not edit files.
- Do not apply patches.
- Do not create tests.
- Do not create temporary scripts or instrumentation files without asking first.
- Do not run formatters or code generators.
- Do not bundle “while I am here” cleanup into the investigation.
- Do not claim a fix is complete; this skill does not fix by default.

## Red Flags

Stop and return to evidence collection if you catch yourself doing any of these:

- Guessing the cause from symptoms.
- Proposing fixes before tracing the source.
- Trying “one quick change.”
- Editing code before reporting the root cause.
- Combining multiple hypotheses.
- Treating a workaround as a root cause.
- Ignoring a working example that differs from the failing path.

## Environmental or External Causes

If the issue is environmental, timing-dependent, or external:

1. Document the evidence that rules out local code causes.
2. Identify the external dependency, timing condition, or environment difference.
3. Recommend monitoring, retry, timeout, configuration, or operational follow-up without implementing it.

## Supporting References

- `root-cause-tracing.md`: use when the bug must be traced backward through call stack or data flow.
- `defense-in-depth.md`: use only to recommend future safeguards after root cause is known.
- `condition-based-waiting.md`: use only when timing, polling, or flaky waits are part of the suspected cause.

Implementation, test-driven-development, or verification skills may be used only after the user explicitly asks for a follow-up fix.
