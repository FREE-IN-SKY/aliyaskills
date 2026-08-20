---
name: karpathy-guidelines
description: 分析需求、制定方案、编写或审查代码、重构及修复缺陷时使用的通用工程准则，强调看清结构、守住原则、说透假设与取舍、优先采用最小现有方案、实施外科式改动、修复根因、堵住同类边界问题、编写具体易懂的注释、合并重复逻辑，并留下最小可运行自检。凡任务将生成或修改代码，必须在动手前先触发此技能。
license: MIT
---

# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls.

These guidelines reduce common LLM coding mistakes by favoring simple, surgical, verifiable changes.

## 1. Understand Before Coding

Before writing code:

* State assumptions explicitly.
* If the task has multiple valid interpretations, name the interpretations instead of silently choosing one.
* If a simpler approach likely solves the real need, say so.
* If the requirement is unclear enough to affect correctness, stop and ask.

For complex requests, first ask: "Do we really need X, or is Y enough?"

## Scope and Evidence Gate

The user's requested observable behavior defines the scope.

Only complexity required by the current request, a verified reachable execution path, a reproduced failure, or an explicit data contract is allowed.

Existing project patterns may guide implementation of an already-justified change, but cannot independently justify new complexity.

Do not design abstractions, configuration, compatibility, fallbacks, extension points, or generalized solutions for hypothetical future requirements.

If correctness requires expanding the requested scope, state the concrete evidence before doing so.

## 2. Think Like a Senior Engineer

Before designing a solution, identify the objects involved and how the objects relate.

If more than two objects have call or dependency relationships, choose a design pattern only when the design pattern solves a concrete problem. Explain what the pattern prevents. If the explanation is weak, do not use the pattern.

Before implementation, give each module one responsibility sentence:

> This module only does X.

Treat "and" in a responsibility sentence as a signal to inspect, not an automatic reason to split.

Split only when the responsibilities have independent callers, change for different reasons, or already cause duplicated logic or mixed ownership.

Do not split when doing so only adds files, interfaces, forwarding code, or coordination between pieces that still change together.

Explain rejected alternatives only when multiple reasonable choices exist and the choice materially affects behavior, scope, risk, or maintainability.

Do not enumerate hypothetical alternatives for routine or obvious decisions.

## 3. Use the Smallest Existing Solution

After understanding the task, walk this ladder and stop at the first level that works:

1. Does this feature need to exist? If not, do not build it.
2. Does the codebase already have this helper, utility, or pattern? Reuse it.
3. Does the standard library solve this? Use the standard library.
4. Does the platform provide a native capability? Use the native capability.
5. Does an existing installed dependency solve this? Use the existing dependency.
6. Can this be one line? Write one line.
7. Otherwise, write the smallest working implementation.

Do not add features, abstractions, configurability, boilerplate, dependencies, or error handling for impossible scenarios.

Deletion is better than addition when deletion solves the problem. Boring code is better than clever code. Fewer files are better unless responsibilities would be mixed. When two standard-library options are similar in size, prefer the one that handles edge cases more correctly.

## 4. Make Surgical Changes

When editing existing code:

* Touch only lines required by the request.
* Match the existing style, even if another style looks better.
* Do not refactor adjacent code unless the request requires it.
* Do not clean up unrelated dead code; mention unrelated dead code separately.
* Remove only imports, variables, functions, or files made unused by your own change.

Every changed line must trace directly to the user request.

The shortest working change wins only when the real execution flow is understood. A small change in the wrong place is still a bug.

## 5. Fix Root Causes, Not Symptoms

For bug reports:

1. Treat the report as a symptom.
2. Find the function that owns the broken behavior.
3. Inspect enough callers to confirm the ownership and affected execution path.
4. Fix a shared entry point only when evidence shows that the same root cause affects multiple currently reachable paths.

Do not modify sibling paths merely because they look similar. Do not broaden the fix to hypothetical callers or unobserved failures.

## 6. Define Verifiable Success

Turn work into checks:

* "Fix the bug" → write or identify a failing check, then make the check pass.
* "Add validation" → check invalid inputs, then make the check pass.
* "Refactor" → verify behavior before and after.

For multi-step work, use:

1. Step → verify: check
2. Step → verify: check
3. Step → verify: check

Loop until the success criteria pass.

Keep local verification focused on the files and packages changed. Run the smallest relevant test set; do not run the full workspace test suite as a routine completion step.

## 7. Check Edge Cases Before Finalizing

Before calling a plan complete, check edge cases that are reachable under the current contract, explicitly requested, observed in real data, or located at a trust boundary:

* Empty input: what happens?
* Out-of-range input: what happens?
* Shared mutable data: can multiple readers or writers overwrite each other?

For each case, state one sentence: either the case is already handled and where, or the case will fail and how the plan fixes the failure.

Do not add validation, fallbacks, retries, or recovery branches for states that the established contract makes impossible.

If the contract is unclear, verify it before adding defensive code.

Do not skip input validation at trust boundaries, data-loss prevention, security, accessibility, hardware calibration, or explicitly requested requirements.

## 8. Keep Comments Concrete

Every function comment starts with what the function does.

If the reason for the function is not obvious, add one sentence explaining why the function exists.

Avoid vague words such as "handle", "manage", "process", and "wrap" unless the sentence says exactly what is being done.

If a simplification is intentional, mark it with:

> dogtail: ...

The `dogtail:` note must state the simplification limit and how to replace the simplified version later.

## 9. Merge Duplicate Logic

After coding, compare functions that appear similar.

If two functions have names and comments that describe the same action, merge the functions.

Do not keep two functions that perform the same responsibility.

## 10. Leave a Minimal Self-Check

For changed non-trivial behavior, use the project's existing verification mechanism when it can catch the regression.

Add a new self-check only when it materially protects the requested behavior and requires no new framework, fixture layer, helper abstraction, or production hook.

When a new self-check is justified, keep it minimal:

* no test framework required,
* no fixtures required,
* a simple assertion or single-file self-check is enough,
* the self-check must fail when the logic breaks.

Do not add tests that only verify implementation details, wording, trivial delegation, or one-line simple implementations.
