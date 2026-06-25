**Taking the Codex tool and Claude Code tool (paired with the GLM5.2 model) as examples, the development workflow is as follows:**

**Step 1: First assess the complexity of the requirement**

**I. For lightweight requirements (using the Codex tool)**

1. Invoke the `/read-code-propose-change` Codex skill and provide a concrete requirement description, letting the skill propose a change plan. This skill suits lightweight-requirement scenarios.
2. If the plan does not cover what you actually want, keep supplementing the requirement description. Many people have not thought their own requirement through; this skill helps clarify it through conversation.
3. Once the requirement is clear and the plan is out, invoke the `/receiving-code-review-custom` Codex skill to review the plan from the previous step and confirm whether it truly satisfies the requirement. This skill applies not only to reviewing plans but also to debugging code, fixing syntax errors, and similar scenarios.
4. After the review, the `/receiving-code-review-custom` skill gives a conclusion: whether the plan can be executed directly, or what content still needs to be supplemented. Once supplemented, proceed to the execution phase.
5. In the execution phase you can invoke the `/test-driven-development` Codex skill (i.e. the test-driven development skill), or directly state what to change and let the AI decide which skill to invoke for execution.

**II. For heavyweight requirements**

**Codex tool part:**

1. Invoke the `/using-superpowers` Codex skill to start the overall Superpowers workflow.
2. Invoke the `/brainstorming-custom` Codex skill and provide a concrete requirement description to discuss the requirement with the AI. After the discussion, this skill writes a spec document (i.e. a requirements specification document).
3. After the spec document passes review, invoke the `/writing-plans-custom` Codex skill to write the concrete implementation plan document. This step does not need to be invoked manually on its own — the `/brainstorming-custom` skill's flow already includes the step of calling `/writing-plans-custom`.

**Claude Code tool (paired with the GLM5.2 model) part:**

1. You can switch to a cheaper domestic AI model and invoke the `/subagent-driven-development` Claude Code skill to execute the concrete development task according to the implementation plan document generated in the previous step.

**Step 2: Acceptance workflow after development is complete**

**Codex tool part:**

1. First do manual testing. If problems are found, describe the specific problem directly in the editing page and let the AI fix it, until all manual tests pass.
2. After testing passes, open a new conversation window and invoke the `/requesting-code-review` Codex skill to review whether the completed code matches the original implementation plan document. This step almost always surfaces some problems.
3. Invoke the `/receiving-code-review-custom` Codex skill to judge whether the problems surfaced in the previous step actually exist and need to be handled.
4. Modify according to the judgment result.
5. One or two rounds of this review-plus-fix loop is enough; do not repeat it endlessly to avoid excessive rework.
6. Open another new conversation window and invoke the `/simplify-custom` Codex skill to do a scan check on code quality and related aspects.
7. Invoke the `/receiving-code-review-custom` Codex skill to judge whether the problems scanned by `/simplify-custom` actually exist.
8. Modify according to the judgment result. After modification, manually ask whether to invoke `/simplify-custom` again for a second scan, and decide whether to continue based on the AI's opinion.

---

**以 Codex 工具与 Claude Code 工具（搭配 GLM5.2 模型）为例，说明开发流程：**

**第一步：先评估需求的复杂程度**

**一、需求较轻量时（使用 Codex 工具）**

1. 调用 `/read-code-propose-change` 这个 Codex 技能，并输入具体需求描述，让该技能给出修改方案。这个技能适用于需求较轻量的场景。
2. 如果方案没有覆盖自己真正想要的内容，就继续补充描述需求。很多人对自己的需求本身就没有想清楚，这个技能可以帮助通过对话把需求理清楚。
3. 需求理清楚、方案也出来之后，调用 `/receiving-code-review-custom` 这个 Codex 技能，对上一步给出的方案进行审核，确认方案是否真正满足需求。这个技能不仅能用于审核方案，调试代码、修复语法错误等场景同样适用。
4. 审核完成后，`/receiving-code-review-custom` 这个技能会给出结论：方案是否可以直接执行，或者需要补充哪些内容。补充完后即可进入执行环节。
5. 执行阶段可以调用 `/test-driven-development` 这个 Codex 技能（即测试驱动开发技能），也可以直接说明要修改的内容，让 AI 自行判断该调用哪个技能去执行。

**二、需求较重量时**

**Codex 工具部分：**

1. 调用 `/using-superpowers` 这个 Codex 技能，启动 Superpowers 整体工作流程。
2. 调用 `/brainstorming-custom` 这个 Codex 技能，并输入具体需求描述，与 AI 进行需求讨论。讨论完成后，这个技能会写出一份 spec 文档（即需求规格说明文档）。
3. spec 文档审核通过后，调用 `/writing-plans-custom` 这个 Codex 技能，编写具体的实施计划文档。这一步不需要手动单独调用，`/brainstorming-custom` 这个技能的流程里已经包含了调用 `/writing-plans-custom` 这一步骤。

**Claude Code 工具（搭配 GLM5.2 模型）部分：**

1. 可以切换到价格更低的国产 AI 模型上，调用 `/subagent-driven-development` 这个 Claude Code 技能，根据上一步生成的实施计划文档执行具体开发任务。

**第二步：开发完成后的验收流程**

**Codex 工具部分：**

1. 先进行手动测试。如果发现问题，就在修改页面里直接描述这个具体问题，让 AI 修复，直到手动测试全部通过为止。
2. 测试通过后，打开一个新的对话窗口，调用 `/requesting-code-review` 这个 Codex 技能，审核已完成的代码是否符合最初的实施计划文档。这一步通常一定会审核出一些问题。
3. 调用 `/receiving-code-review-custom` 这个 Codex 技能，判断上一步审核出的问题是否真实存在、是否需要处理。
4. 根据判断结果进行修改。
5. 这个审核加修改的循环做一到两轮即可，不需要反复进行，避免过度返工。
6. 再打开一个新的对话窗口，调用 `/simplify-custom` 这个 Codex 技能，对代码质量等方面进行一次扫描检查。
7. 调用 `/receiving-code-review-custom` 这个 Codex 技能，判断 `/simplify-custom` 扫描出的问题是否真实存在。
8. 根据判断结果进行修改。修改完成后，手动询问是否需要再次调用 `/simplify-custom` 这个技能做二次扫描，并根据 AI 给出的意见决定是否继续操作。
