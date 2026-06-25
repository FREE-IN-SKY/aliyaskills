# aliyaskills

**Philosophy**: Commit power stays with the programmer. Until a requirement is fully done, code stays in the working tree; commits are made by a human, not the agent framework.

A daily-use AI programming skill library. Based on [superpowers](https://github.com/obra/superpowers.git), it contains a set of custom-version workflow skills, plus conversation-rule files meant to be placed in a project's root directory.

## Composition

### 1. Conversation-rule files (placed in the project root when writing a project)

The rules come in Chinese and English versions with identical content; only the filenames differ, because Claude Code and Codex scan different default filenames.

- `CLAUDE_ZH.md` / `AGENTS_ZH.md` — Chinese version, for Claude Code / Codex respectively
- `CLAUDE_EN.md` / `AGENTS_EN.md` — English version, for Claude Code / Codex respectively

Claude Code auto-scans a file named `CLAUDE*.md` in the project root; Codex auto-scans `AGENTS*.md`. Pick the tool you use, then pick the language version, and copy the corresponding file into the project root (renaming it to `CLAUDE.md` / `AGENTS.md` as needed). Rule highlights: answers terse, first response triggers `caveman -- ultra`, no modifying Git history or remotes, describe project state from the perspective of UI operations.

### 2. Skill library

Skills fall into two categories:

**Original superpowers skills** — directly from superpowers, the foundation of the workflow framework.

**Custom-version skills** — derived from the superpowers versions, tailored to the actual usage workflow. Prefer the custom version for workflow tools:

| Skill | Purpose |
|------|------|
| `brainstorming-custom` | discuss requirement, produce spec |
| `writing-plans-custom` | write implementation plan from spec |
| `receiving-code-review-custom` | judge whether review comments are valid |
| `simplify-custom` | code-quality scan |
| `systematic-debugging-custom` | systematic troubleshooting |
| `caveman` | compressed output style |
| `karpathy-guidelines` | senior-engineer engineering principles |
| `read-code-propose-change` | read code and propose plan for lightweight requirements |
| others | `agent-creator`, `frontend-design`, `playwright-cli`, `smart-docs`, `theme-factory`, `webapp-testing`, etc. |

## Prerequisites

Before use, install superpowers yourself:

```
git@github.com:obra/superpowers.git
```

The custom-version skills build on superpowers' workflow framework; some workflow skills will not work properly without it installed.

## Workflow

The full workflow is in [self vibe coding process.md](self%20vibe%20coding%20process.md). Summary:

- **Lightweight requirement**: `read-code-propose-change` proposes plan → `receiving-code-review-custom` reviews plan → execute once satisfied (optionally with `test-driven-development`).
- **Heavyweight requirement**: codex side `using-superpowers` → `brainstorming-custom` discusses requirement and produces spec → `writing-plans-custom` writes plan → claude code side uses a cheaper model with `subagent-driven-development` to execute the plan.
- **After development**: manual test → `requesting-code-review` reviews against plan → `receiving-code-review-custom` judges whether problems are real → fix → `simplify-custom` scans quality → `receiving-code-review-custom` re-checks → fix. One or two rounds is enough; do not over-iterate.

---

# aliyaskills

**理念**：提交代码的权力归程序员。在需求未完全实现之前，代码停留在工作区；提交由人工完成，而非 agent 框架替人提交。

日常使用的 AI 编程技能库。基于 [superpowers](https://github.com/obra/superpowers.git)，包含一套自定义的 custom 版本流程技能，以及放项目根目录用的会话规则文件。

## 组成

### 1. 会话规则文件（写项目时放项目根目录）

规则分中文版与英文版，内容完全一样，只是文件名不同，因为 Claude Code 与 Codex 默认扫描的文件名不一样。

- `CLAUDE_ZH.md` / `AGENTS_ZH.md` — 中文版，分别对应 Claude Code / Codex
- `CLAUDE_EN.md` / `AGENTS_EN.md` — 英文版，分别对应 Claude Code / Codex

Claude Code 会自动扫描项目根目录下 `CLAUDE*.md` 命名的文件，Codex 则扫描 `AGENTS*.md`。按使用的工具选定后，再选语言版本，把对应文件复制进项目根目录（按需重命名为 `CLAUDE.md` / `AGENTS.md`）即可。规则要点：回答言简意赅、首次响应先触发 `caveman -- ultra`、禁止修改 Git 历史与远端、描述项目情况以界面操作角度说明。

### 2. 技能库

技能分两类：

**superpowers 原版技能** — 直接来自 superpowers，流程框架的基础。

**custom 版本技能** — 脱胎于 superpowers 版本，针对实际使用流程定制。流程工具优先用 custom 版本：

| 技能 | 用途 |
|------|------|
| `brainstorming-custom` | 聊需求、产出 spec |
| `writing-plans-custom` | 基于 spec 写实施计划 |
| `receiving-code-review-custom` | 判断审核意见是否属实 |
| `simplify-custom` | 代码质量扫描 |
| `systematic-debugging-custom` | 系统化排障 |
| `caveman` | 压缩输出风格 |
| `karpathy-guidelines` | 资深工程师工程准则 |
| `read-code-propose-change` | 轻量需求读码出方案 |
| 其余 | `agent-creator`、`frontend-design`、`playwright-cli`、`smart-docs`、`theme-factory`、`webapp-testing` 等 |

## 前置安装

使用前需自行安装 superpowers：

```
git@github.com:obra/superpowers.git
```

custom 版本技能基于 superpowers 的流程框架，未安装则部分流程技能无法正常工作。

## 使用流程

完整流程见 [self vibe coding process.md](self%20vibe%20coding%20process.md)。摘要：

- **轻量需求**：`read-code-propose-change` 出方案 → `receiving-code-review-custom` 审方案 → 满意后执行（可用 `test-driven-development`）。
- **重量需求**：codex 端 `using-superpowers` → `brainstorming-custom` 聊需求出 spec → `writing-plans-custom` 写计划 → claude code 端用便宜模型 `subagent-driven-development` 执行计划。
- **开发完成后**：手动测试 → `requesting-code-review` 对照 plan 审 → `receiving-code-review-custom` 判断问题属实 → 修改 → `simplify-custom` 扫质量 → `receiving-code-review-custom` 复核 → 修改。一两次即可，不过度。
