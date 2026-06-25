---
name: simplify-custom
description: Review changed code for reuse, quality, and efficiency, report findings, then fix after user confirmation.
---

# Simplify Skill

Use this skill when the user asks to simplify, clean up, review, refactor, or improve changed code.

## Goal

Review the current code changes from three angles:

1. Code reuse
2. Code quality
3. Efficiency

Report the real issues first. Wait for user confirmation before applying fixes.

## Phase 1: Identify Changes

1. Check the repository state:

```bash
git status --short
git diff
git diff --staged
```

2. If staged changes exist, review both unstaged and staged changes.
3. If there are no git changes, review the files most recently edited or explicitly mentioned by the user.
4. Do not make unrelated changes.

## Phase 2: Prepare Review Context

Create a complete review context that includes:

- The full diff.
- The files touched.
- Nearby code needed to understand the change.
- Existing utilities, helpers, shared modules, and adjacent files that may already solve the same problem.

Prefer repository search tools such as `rg`, `find`, and language-aware search when available.

## Phase 3: Run Three Agent Reviews

Run these three review agents as independent review passes over the same diff.

If the environment supports parallel agents, run them in parallel. If not, run the same three reviews sequentially and keep their findings separate.

### Agent 1: Code Reuse Review

Check whether the changes duplicate existing code.

Look for:

1. Existing utilities or helpers that can replace newly added logic.
2. New functions that duplicate existing functions.
3. Inline logic that should use an existing abstraction, such as:
   - String manipulation
   - Path handling
   - Environment checks
   - Type guards
   - Formatting helpers
   - Validation helpers
4. Similar patterns in:
   - Utility directories
   - Shared modules
   - Adjacent files
   - Existing tests

For each finding, record:

- The changed code.
- The existing code that should be reused.
- The recommended replacement.

### Agent 2: Code Quality Review

Check whether the changes introduce brittle or messy code.

Look for:

1. Redundant state that can be derived from existing state.
2. Cached values that do not need to be cached.
3. Effects, observers, or listeners that could be direct calls.
4. Parameter sprawl, especially adding more parameters instead of improving the data shape.
5. Copy-paste blocks with small variations.
6. Leaky abstractions that expose internal details.
7. Raw strings where constants, enums, union types, or existing identifiers should be used.
8. Unnecessary JSX or component nesting.
9. Deeply nested conditionals, ternary chains, or switches.
10. Comments that explain what obvious code does instead of why non-obvious code exists.

For each finding, record:

- The issue.
- Why it matters.
- The simplest fix.

### Agent 3: Efficiency Review

Check whether the changes introduce unnecessary work.

Look for:

1. Repeated computation.
2. Repeated file reads.
3. Duplicate network or API calls.
4. N+1 query or request patterns.
5. Independent async work that is run sequentially.
6. New blocking work in startup, request, render, or hot paths.
7. Unconditional state or store updates in polling loops, intervals, subscriptions, or event handlers.
8. Updater wrappers that ignore same-reference returns or other no-change signals.
9. Existence checks before file or resource operations when direct operation plus error handling is safer.
10. Unbounded data structures.
11. Missing cleanup for listeners, timers, subscriptions, or handles.
12. Loading all data when only one item or a small slice is needed.

For each finding, record:

- The inefficient code.
- The cost or risk.
- The simplest fix.

## Phase 4: Aggregate Findings

Combine the three reviews.

For each finding:

1. Keep it if it is real and relevant.
2. Skip it if it is a false positive.
3. Skip it if the fix would make the code more complex without clear benefit.
4. Prefer small, direct fixes.
5. Avoid broad rewrites unless the current change clearly requires them.

Do not argue with skipped findings. Just note that they were skipped.

## Phase 5: Report Findings And Wait

Report the review findings before editing code.

The report must include:

1. What was reviewed.
2. Real findings grouped by reuse, quality, and efficiency.
3. Findings skipped as false positives or not worth changing.
4. The proposed fixes.
5. A clear request for confirmation before changing files.

Stop after this report. Do not edit files until the user confirms.

## Phase 6: Fix Issues

After user confirmation, apply fixes directly.

Rules:

1. Preserve current behavior unless the user explicitly asked for behavior changes.
2. Reuse existing helpers before adding new ones.
3. Keep edits local to the changed area when possible.
4. Add or update tests when the codebase already has relevant tests.
5. Remove unnecessary comments.
6. Do not reformat unrelated files.
7. Do not change public APIs unless necessary.

## Phase 7: Validate

Run the smallest useful validation command.

Prefer, in order:

1. Targeted tests for changed files.
2. Related test files.
3. Typecheck or lint for the affected package.
4. Full test suite only when the change scope requires it.

If validation cannot be run, explain why.

## Phase 8: Report And Rerun Judgment

Return a short summary with:

1. What was reviewed.
2. What was fixed.
3. What was skipped, if anything.
4. What validation was run and the result.
5. Whether running `simplify` again is recommended.

The rerun judgment must be explicit:

- Say `Do not rerun simplify` when the fixes were small, behavior was preserved, validation passed, and no meaningful review risk remains.
- Say `Rerun simplify recommended` when the fixes changed enough code to deserve another pass, introduced new structure, skipped risky items, or validation could not be run or did not pass.

Do not automatically run `simplify` again. Only report the recommendation and wait for the user to decide.

Keep the report concise.
