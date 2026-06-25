# aliyaskills

日常使用的 AI 编程技能库。基于 [superpowers](https://github.com/obra/superpowers.git)，包含一套自定义的 custom 版本流程技能，以及放项目根目录用的会话规则文件。

## 组成

### 1. 会话规则文件（写项目时放项目根目录）

- `CLAUDE.md` — Claude Code 的会话规则
- `AGENTS.md` — Codex 的会话规则

两者内容完全一样，按使用的工具二选一放项目根目录即可。规则要点：回答言简意赅、首次响应先触发 `caveman -- ultra`、首次生成代码前先触发 `karpathy-guidelines`、禁止修改 Git 历史与远端、描述项目情况以界面操作角度说明。

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
