# aliyaskills

**Philosophy**: Commit power stays with the programmer. Until a requirement is fully done, code stays in the working tree; commits are made by a human, not the agent framework.

Always stay skeptical of the AI's comprehension: when it hits something uncertain, it won't tell you — it'll make something up and keep going. After handing off key info, ask one more question — "do you understand what I mean?" — and have it restate its understanding before you confirm. The restatement must be in its own words, not a copy of what you said — that's the only way to actually tell whether it understood, instead of finding out it misread you after the work is done, when it's too late.

A daily-use AI programming skill library, inspired by [superpowers](https://github.com/obra/superpowers.git), customized for day-to-day comfort. It contains a set of custom-version workflow skills, plus conversation-rule files meant to be placed in a project's root directory.

## Composition

### 1. Conversation-rule files (placed in the project root when writing a project)

The rules come in Chinese and English versions with identical content:

- `AGENTS_ZH.md` — Chinese version
- `AGENTS_EN.md` — English version

Codex auto-scans a file named `AGENTS*.md` in the project root. Pick the language version and copy it into the project root (renaming it to `AGENTS.md` as needed). Rule highlights: first response triggers `caveman — ultra`, all answers in English, subagent tools allowed. A Codex hook (`hooks/block-git-write.sh`, wired via `hooks.json`) blocks any git command that mutates history or remotes, keeping commit/push under human control.

### 2. Skill library

Skills fall into two categories:

**Custom-version skills** — derived from the superpowers versions, tailored to the actual usage workflow.

| Skill | Purpose |
|------|------|
| `brainstorming-custom` | discuss requirement, produce spec, manual invocation only |
| `writing-plans-custom` | write implementation plan from spec |
| `receiving-code-review-custom` | judge whether review comments are valid |
| `systematic-debugging-custom` | systematic troubleshooting |
| `caveman` | compressed output style |
| `karpathy-guidelines` | senior-engineer engineering principles |
| `code-reader` | read unfamiliar codebase, produce reusable knowledge skill |
| `dispatching-parallel-agents` | dispatch 2+ independent tasks in parallel |
| `executing-plans` | execute a plan across sessions with review checkpoints |
| `phased-subagent-development` | run an existing plan phase-by-phase via subagents |
| `project-explorer` | interactive, staged project learning |
| `requesting-code-review` | verify finished work against requirements |
| `test-driven-development` | write tests before implementation |
| `verification-before-completion` | verify before claiming work done |
| others | `agent-creator`, `frontend-design`, `smart-docs`, `webapp-testing`, etc. |

## Workflow

- **Lightweight requirement**: chat directly with the AI about the requirement, then let it start work; the AI auto-invokes the matching skill based on each skill's description.
- **Heavyweight requirement**: manually invoke `brainstorming-custom` to kick off the flow, then follow the prompts the flow itself gives (it chains into `writing-plans-custom`, etc.).
- **After development**: manual test — file a bug and let the AI fix it if you find one, otherwise it's done.

---

# aliyaskills

**理念**：提交代码的权力归程序员。在需求未完全实现之前，代码停留在工作区；提交由人工完成，而非 agent 框架替人提交。

永远对 AI 的理解能力保持质疑：AI 遇到不确定的地方不会告诉你,它会自己脑补一个然后接着往下走. 交代完关键信息后,多问一句"你懂我意思吗",让它复述理解,你再确认. 复述必须是它自己的话,不是照抄你说的——这样你才能真正判断它是不是懂了,而不是等做完了才发现理解错了,那时候已经晚了.

日常使用的 AI 编程技能库，参考了 [superpowers](https://github.com/obra/superpowers.git)，从日常使用中舒适度进行定制修改, 包含一套自定义的 custom 版本流程技能，以及放项目根目录用的会话规则文件。

## 组成

### 1. 会话规则文件（写项目时放项目根目录）

规则分中文版与英文版，内容完全一样：

- `AGENTS_ZH.md` — 中文版
- `AGENTS_EN.md` — 英文版

Codex 会自动扫描项目根目录下 `AGENTS*.md` 命名的文件。按语言版本选好后，复制进项目根目录（按需重命名为 `AGENTS.md`）即可。规则要点：首次响应先触发 `caveman -- ultra`、所有回答基于中文、允许 subagent 工具调用。Codex 钩子（`hooks/block-git-write.sh`，经 `hooks.json` 接入）会拦截所有修改 Git 历史或远端的命令，提交/推送仍由人工掌控。

### 2. 技能库

技能分两类：

**custom 版本技能** — 脱胎于 superpowers 版本，针对实际使用流程定制。

| 技能 | 用途 |
|------|------|
| `brainstorming-custom` | 聊需求、产出 spec, 只有手动调用才会调用 |
| `writing-plans-custom` | 基于 spec 写实施计划 |
| `receiving-code-review-custom` | 判断审核意见是否属实 |
| `systematic-debugging-custom` | 系统化排障 |
| `caveman` | 压缩输出风格 |
| `karpathy-guidelines` | 资深工程师工程准则 |
| `code-reader` | 读陌生代码库，产出可复用认知技能 |
| `dispatching-parallel-agents` | 派发 2+ 个独立任务并行执行 |
| `executing-plans` | 跨会话执行计划，带审查点 |
| `phased-subagent-development` | 用子代理分阶段执行已有计划 |
| `project-explorer` | 交互式分阶段了解项目 |
| `requesting-code-review` | 完成后对照需求验收审查 |
| `test-driven-development` | 先写测试再实现 |
| `verification-before-completion` | 声明完成前先验证 |
| 其余 | `agent-creator`、`frontend-design`、`smart-docs`、`webapp-testing` 等 |

## 使用流程

- **轻量需求**：直接跟 AI 聊需求，聊完让 AI 直接开始做，AI 会根据各技能的 description 自动判断该调用哪个。
- **重量需求**：手动调用 `brainstorming-custom` 启动流程，之后按该流程本身给出的提示往下走（会自动衔接到 `writing-plans-custom` 等步骤）。
- **开发完成后**：手动测试，有 bug 就提 bug 让 AI 修，没有 bug 就算过。
