---
name: systematic-debugging-custom
description: 当用户明确要求对可复现缺陷、测试失败、构建失败、已确认的性能回退或异常运行行为进行根因分析时使用。先复现或收集证据, 追踪执行与数据路径, 只读验证单一假设, 报告根因及拟改范围后停止, 等待用户明确确认。
---

# Systematic Debugging

This skill performs diagnosis only. It does not implement fixes.

## Core Constraints

Do not modify code, tests, configuration, dependencies, or other files before completing the root-cause investigation and receiving explicit user confirmation. Do not present a symptom, correlation, or unverified guess as the root cause.

## Diagnostic Workflow

Follow these steps in order. If evidence is insufficient, stop at the current step instead of moving to a fix.

### 1. Reproduce or Gather Evidence

- Read the complete error messages, stack traces, logs, failing checks, and relevant environment information.
- Prefer a reliable reproduction. Record the triggering steps, actual result, and expected result.
- If the issue cannot be reproduced, gather evidence from existing logs, read-only commands, history, and runtime state. State what evidence is still missing.
- Inspect recent code, configuration, dependency, and environment changes related to the failure.

### 2. Trace Execution and Data Flow

- Find the function or component that directly produces the incorrect behavior.
- Inspect callers and input sources backward until locating where the incorrect state first appears.
- In multi-component systems, inspect inputs, outputs, state, and configuration propagation at component boundaries to locate the first failing layer.
- When the error occurs deep in the call stack or the source of an incorrect value is unclear, read and use [root-cause-tracing.md](root-cause-tracing.md).

### 3. Form One Hypothesis

State one specific hypothesis supported by the current evidence:

> X is the root cause because evidence Y explains failure chain Z.

Do not test multiple hypotheses at once. Do not use a fix as a validation method.

### 4. Validate Read-Only

- Use existing tests, logs, queries, version history, or runtime inspection to test one variable.
- If the evidence supports the hypothesis, confirm that it explains the complete causal chain rather than only the local symptom.
- If the evidence rejects the hypothesis, return to evidence gathering and form a new single hypothesis from the new evidence.
- If validation requires modifying any file or adding diagnostic code, do not make the change. Include the required diagnostic change and its reason in the report, then wait for user confirmation.

### 5. Report and Stop

Report:

- The reproduction result or observed evidence.
- The confirmed root cause and complete causal chain. If not confirmed, state the uncertainty and missing evidence explicitly.
- The smallest proposed change and why it addresses the root cause.
- The files and scope expected to change.
- The minimum verification to run after the change.

After reporting, stop and wait for explicit user confirmation.

## Prohibited Actions

- Proposing a fix without reproduction or supporting evidence.
- Modifying files, applying trial patches, or changing multiple variables to test a guess.
- Assuming the location nearest the error is the root cause.
- Crossing the confirmation gate and starting implementation during the same diagnostic turn.
