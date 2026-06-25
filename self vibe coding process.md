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