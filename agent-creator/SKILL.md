---
name: agent-creator
description: A knowledge pack for designing and creating Claude Code agent files. Use this skill when the user wants to create a new agent, doesn't know what to put in an agent file, or wants to evaluate whether an existing agent is well-written. Even if the user simply says "help me write an agent", this skill should be triggered.
---

# Agent Creator

The purpose of this skill is to help design well-structured Claude Code agent files.

## What Is an Agent

An agent is a `.md` file that is either automatically invoked by an AI tool at the right moment, or manually called by the user by name. Where the file is stored depends on the tool you are using and the scope you want it to apply to — refer to your tool's documentation.

An agent is not a procedural script. It is an AI role with an identity, a goal, clear boundaries, and the ability to decide for itself how to get things done.

## Agent File Structure

```
---
name: the agent's name (lowercase with hyphens)
description: when to call this agent — describe the triggering scenario clearly
model: inherit
---

Body: written in plain language — who this agent is, what it does, what it must not do, how it works, and what it outputs
```

## What a Good Agent Contains

### 1. Identity (Who It Is)
State in one sentence what role this agent plays.

```markdown
You are a senior code reviewer.
```

### 2. Goal (What Result It Is Responsible For)
Make clear what this agent is accountable for and what it delivers.

```markdown
Your goal is to review completed code changes for correctness, maintainability, plan alignment, test quality, and security risk.
```

### 3. Working Style and Scope
Describe how this agent approaches its work and what its attitude is. Do not hardcode which skill to use — the AI will judge that based on the situation.

```markdown
You approach problems methodically. You never guess — you only draw conclusions from evidence.
```

### 4. Boundaries (What It Must Not Do)
Explicitly state what this agent is not allowed to do, to prevent it from overstepping.

```markdown
Do not modify code unless explicitly asked.
Do not make assumptions about intent — ask if unclear.
```

### 5. Available Skills
List the skills this agent can invoke. Let the AI decide when to use them and whether to use them at all. Do not hardcode the invocation logic.

```markdown
You have access to the following skills: python-testing, security-review.
Use them when relevant. You decide when and whether to invoke them.
```

### 6. What to Do When a User Decision Is Required
A sub-agent runs to completion and returns its result to the main conversation — it cannot pause mid-run to wait for user input. There are two practical ways to handle this:

Option one: Write the default behavior for ambiguous situations directly into the agent file. For example: "When uncertain, choose the most conservative option and document the assumptions made in the output."

Option two: Write into the agent file that when an uncertain point is encountered, the agent must immediately stop all further actions and return the following as its final output:
- What is causing the uncertainty
- What the safe options are if execution is to continue

The main conversation then presents this result to the user, gets a decision, and launches a new sub-agent — passing in the original context plus the user's decision to continue from where things stopped.

```markdown
If you encounter an ambiguous situation that requires a decision, stop immediately. Do not proceed or guess. Return your current progress and clearly describe: why you are uncertain and what the safe options are to continue.
```

### 7. Output Requirements (What Format to Deliver)
Tell the agent what to return at the end. Keep the format concise and consistent.

```markdown
Return:
1. Summary
2. Issues (Critical / Important / Suggestion)
3. Recommended next actions
```

## Core Design Principles

**Write responsibilities, not procedures.**
Do not stuff "step one do this, step two do that" into an agent. That is a workflow — it is not what an agent should carry.

**Write judgment criteria, not decision branches.**
Don't write:
```markdown
If the code touches auth, use security-review.
If the code touches tests, use python-testing.
```
Write instead:
```markdown
Use judgment to decide which skills are relevant based on the actual change, risk level, and project context.
```

**The AI decides how to use skills.**
An agent file is essentially giving the AI an identity and a defined capability range. Once the AI reads it, the AI takes on that identity and faces the current task — deciding on its own when to use which skill and whether to combine skills. The agent file only needs to tell the AI which skills are available. The judgment and the actual use are entirely the AI's responsibility.

**A good agent is like a seasoned colleague, not an assembly-line robot.**

## Creation Modes

There are two creation modes. Before starting, ask the user to enter a number to choose:

1. Manual creation
2. Auto-aggregation recommendation

If the user directly states their needs at the start without choosing a mode, first ask whether they want mode 1 or mode 2, then carry their stated needs into whichever mode they choose.

If the user states their needs at any point during mode 2, do not interrupt the current flow. Instead, treat the user's stated needs as the highest priority and the inferred user profile as the second priority. Re-run the step 2 aggregation logic (no need to re-scan skills) and generate a new set of proposals to show the user.

**Mode 1: Manual Creation**
The user describes the agent's responsibilities. Design the agent step by step following the "Manual Creation Steps" section.

**Mode 2: Auto-Aggregation Recommendation**
1. First determine the current tool platform (by examining the current directory structure and configuration files), then use the `find` command to search for all `SKILL.md` files only within the directory scope corresponding to that platform (e.g., for Claude Code, search only within `.claude/`-related directories; for Codex, search only within `.codex/`-related directories). Do not scan across platforms. Once found, read the name, description, and body content of each skill file, and infer the user's technical direction and working habits from them.
2. Based on the scan results, infer the user's technical direction and working habits, and aggregate 3–5 agent proposals. Selection criteria: each proposal must be the best match for the inferred user profile, with a clear identity, specific responsibilities, and well-defined boundaries — like an employee with a real job title at a company, not a feature module.
3. Present the proposed agents to the user for selection. Describe each proposal in plain language, avoiding jargon, so that someone with no technical background can immediately understand it. Each proposal must include:
   - What this agent is for (one sentence)
   - Why it was inferred that the user needs it
   - What situations it would be used in
   - What outcome it produces when used
   - Which skills are recommended for this agent (selected from the scanned skills, with an explanation of why each skill matches this agent's responsibilities)

   If the user does not directly select a proposal but instead states their own needs, treat the user's stated needs as the highest priority and the inferred user profile as the second priority. Re-run the step 2 aggregation logic (no need to re-scan skills) and generate a new set of 3–5 proposals to present again.
4. After the user confirms, if the user disagrees with the recommended skill configuration, first let the user confirm the final skill scope before generating the complete agent file. Auto-detect the current tool platform (via directory structure and configuration files). Before generating, ask the user:
   1. Use only in the current project
   2. Use across all projects
   Based on the user's selection, place the agent file in either the platform's project-level agent directory or the global agent directory. If the directory does not exist, create it automatically. If the platform cannot be determined automatically, then ask the user.
5. Write the name and description of each sub-agent into the corresponding platform's configuration file, so that the main conversation can determine when to call which sub-agent directly from the description — without needing to scan the agent folder each time.

## Manual Creation Steps

For the agent the user wants to create, ask in depth about each key decision point one at a time until full agreement is reached. Work through every branch of the decision tree and resolve dependencies between decisions in order. Ask only one question at a time, and provide your recommended answer.

For any question that can be answered by using `find` to search all `SKILL.md` files within the current platform's directory, do the search first and present the results as recommended options for the user to choose from — do not ask the user directly.

Points to clarify:
- Who is this agent? What role does it play? What is its working style?
- What result is this agent accountable for?
- What must this agent absolutely never do?
- Which skills can this agent use? Use `find` to search all `SKILL.md` files within the current platform's directory, then list the found skills for the user to choose from — do not ask the user directly.
- When uncertain, should the agent default to conservative handling, or stop immediately and return to the main conversation?
- What format should the final output be delivered in?

Once all key points are confirmed, ask the user:
   1. Use only in the current project
   2. Use across all projects
Based on the user's selection, place the agent file in either the platform's project-level agent directory or the global agent directory. If the directory does not exist, create it automatically. After generating the file, also write this agent's name and description into the corresponding platform's configuration file.

## How to Evaluate Whether an Agent Is Well-Written

Ask these questions:

- Is the identity clear? Can you describe who it is and how it works in one sentence?
- Is the goal specific? Does it know what result it is accountable for?
- Is too much "how to do it" hardcoded in?
- Is the skill list being used to define the agent's identity? Identity should be defined by responsibilities and style, not by a list of skills.
- Is the skill scope clearly defined? The agent file should explicitly list the available skills and let the AI decide when to use them — not leave out any skill declarations, and not dump every skill in either.
- Are the boundaries clear? Does it know what it must not do?
- Is the output format fixed?

## Complete Example (The skill names in this example are for illustration only. Replace them with the actual skill names that exist in your project.)

```markdown
---
name: code-reviewer
description: Invoke when a meaningful code change has been completed and needs to be reviewed. For example: a feature has been finished, a bug has been fixed, or a refactor has been done.
model: inherit
---

You are a senior code reviewer. You are thorough, direct, and constructive. You read code carefully before judging it, and you never comment on things you haven't verified.

Your goal is to review completed code changes for correctness, maintainability, plan alignment, test quality, security risk, and architectural fit.

You have access to the following skills: python-testing, security-review.
Use them when relevant based on the actual task. You decide when and whether to invoke them.

Do not modify code unless explicitly asked.

Return:
1. Summary
2. What looks good
3. Critical issues
4. Important issues
5. Suggestions
6. Plan or requirement deviations
7. Recommended next actions

Keep feedback specific, concise, and actionable.
```