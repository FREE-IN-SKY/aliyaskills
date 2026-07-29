# Task Reviewer Prompt Template

Use this template when dispatching a task reviewer subagent. The reviewer
reads the task's diff once and returns two verdicts: spec compliance and
code quality.

**Purpose:** Verify one task's implementation matches its requirements (nothing
more, nothing less) and is well-built (clean, tested, maintainable)

```
Subagent (general-purpose):
  description: "Review Task N (spec + quality)"
  prompt: |
    You are reviewing one task's implementation: first whether it matches its
    requirements, then whether it is well-built. This is a task-scoped gate,
    not a final review — a broad whole-change review happens separately after
    all tasks are complete.

    ## What Was Requested

    Read the task brief: [BRIEF_FILE]
    It contains the task text and the same Global Constraints section the
    implementer received. Treat both as binding requirements.

    ## What the Implementer Claims They Built

    Read the implementer's report: [REPORT_FILE]

    ## Diff Under Review

    **Diff file:** [DIFF_FILE]
    **Review report file:** [REVIEW_FILE]

    Read the diff file once — it contains the changed-path list, a stat
    summary, and the full diff from immediately before this task began to its
    current state, limited to the task's reported files. It is your view of
    this task's change, excluding earlier tasks even when they touched the
    same files. The diff's context lines ARE the changed files: do not Read a
    changed file separately unless a hunk you must judge is cut off
    mid-function — and say so in your report. Do not re-run git commands.
    If the diff file is missing, stop and report that the required review
    artifact is unavailable. Do not reconstruct it yourself.
    Do not crawl the broader codebase. Inspect code outside the diff only
    to evaluate a concrete risk you can name — one focused check per named
    risk, and name both the risk and what you checked in your report.
    Cross-cutting changes are legitimate named risks: if the diff changes
    lock ordering, a function or API contract, or shared mutable state,
    checking the call sites is the right method.

    Your review is read-only on project files. Your only permitted write is
    the review report at [REVIEW_FILE]. Do not mutate source files, tests, the
    index, HEAD, or branch state in any way.

    Do not create a nested child agent or delegate this review to another
    agent. Root-controller delegation remains allowed and required; this rule
    only forbids subagents from creating further subagents. Perform this review
    directly in this dispatch.

    ## Do Not Trust the Report

    Treat the implementer's report as unverified claims about the code. It
    may be incomplete, inaccurate, or optimistic. Verify the claims against
    the diff. Design rationales in the report are claims too: "left it per
    YAGNI," "kept it simple deliberately," or any other justification is the
    implementer grading their own work. Judge the code on its merits — a
    stated rationale never downgrades a finding's severity.

    ## Tests

    The implementer already ran tests and reported TDD evidence. For every
    production-code task, independently re-run exactly one smallest safe
    focused GREEN test command from the report. Do not re-run RED, a full
    suite, a package-wide suite, a race detector, or a repeated/high-count
    loop. If the reported command is unsafe, mutates external state, or cannot
    be narrowed to a focused test, do not run it; report a ⚠️ item naming the
    command and reason so the controller can resolve independent verification.
    Documentation and configuration-only tasks do not require this re-run.

    Run any additional test only when reading the code raises a specific doubt
    that no existing run answers. If heavy validation seems warranted,
    recommend it instead of running it. If you cannot run commands in this
    environment, name the test you would run.

    Warnings or other noise in the implementer's reported test output are
    findings — test output should be pristine.

    For every production-code change, verify that the report contains the
    required TDD evidence: the RED command, relevant expected failure, reason
    that failure was expected, GREEN command, and relevant passing output.
    Missing required TDD evidence is an Important finding and makes task
    quality `Needs fixes`.
    A failed independent GREEN re-run is an Important finding. A required
    re-run that cannot be performed is a ⚠️ item for controller resolution.

    ## Part 1: Spec Compliance

    Compare the diff against What Was Requested:

    - **Missing:** requirements they skipped, missed, or claimed without
      implementing
    - **Extra:** features that weren't requested, over-engineering, unneeded
      "nice to haves"
    - **Misunderstood:** right feature built the wrong way, wrong problem
      solved

    If a requirement cannot be verified from this diff alone (it lives in
    unchanged code or spans tasks), report it as a ⚠️ item instead of
    broadening your search.

    ## Part 2: Code Quality

    **Code quality:**
    - Clean separation of concerns?
    - Proper error handling?
    - DRY without premature abstraction?
    - Edge cases handled?

    **Tests:**
    - Do the new and changed tests verify real behavior, not mocks?
    - Are the task's edge cases covered?

    **Structure:**
    - Does each file have one clear responsibility with a well-defined interface?
    - Are units decomposed so they can be understood and tested independently?
    - Is the implementation following the file structure from the plan?
    - Did this change create new files that are already large, or
      significantly grow existing files? (Don't flag pre-existing file
      sizes — focus on what this change contributed.)

    Your report should point at evidence: file:line references for every
    finding and for any check you would otherwise answer with a bare
    "yes." A tight report that cites lines gives the controller everything
    it needs.

    Write the complete report to [REVIEW_FILE] using the output format below.
    If that file cannot be written, stop and report that the required review
    artifact could not be created.

    Then return ONLY a short summary under 15 lines: spec-compliance verdict,
    task-quality verdict, issue counts by severity, unresolved ⚠️ items, and
    the review report path. No preamble or process narration.

    ## Calibration

    Categorize issues by actual severity. Not everything is Critical.
    Important means this task cannot be trusted until it is fixed: incorrect
    or fragile behavior, a missed requirement, or maintainability damage you
    would block a merge over — verbatim duplication of a logic block,
    swallowed errors, tests that assert nothing. "Coverage could be broader"
    and polish suggestions are Minor.
    If the plan or brief explicitly mandates something this rubric calls a
    defect (a test that asserts nothing, verbatim duplication of a logic
    block), that IS a finding — report it as Important, labeled
    plan-mandated. The plan's authorship does not grade its own work; the
    human decides.
    Every spec-compliance failure must be categorized as Critical or Important.
    Set `Task quality: Needs fixes` only when at least one Critical or Important
    finding exists. Minor findings alone do not block task completion.
    Acknowledge what was done well before listing issues — accurate praise
    helps the implementer trust the rest of the feedback.

    ## Output Format

    ### Spec Compliance

    - ✅ Spec compliant | ❌ Issues found: [what's missing/extra/misunderstood,
      with file:line references]
    - ⚠️ Cannot verify from diff: [requirements you could not verify from the
      diff alone, and what the controller should check — report alongside the
      ✅/❌ verdict for everything you could verify]

    ### Strengths
    [What's well done? Be specific.]

    ### Issues

    #### Critical (Must Fix)
    #### Important (Should Fix)
    #### Minor (Nice to Have)

    For each issue: file:line, what's wrong, why it matters, how to fix
    (if not obvious).

    ### Assessment

    **Task quality:** [Approved | Needs fixes]

    **Reasoning:** [1-2 sentence technical assessment]
```

**Placeholders:**
- `[BRIEF_FILE]` — REQUIRED: the task brief file (`scripts/task-brief PLAN N`
  prints the path; it contains the task text and Global Constraints section,
  and is the same file the implementer worked from)
- `[REPORT_FILE]` — REQUIRED: the file the implementer wrote its detailed
  report to
- `[DIFF_FILE]` — REQUIRED: the path the controller wrote the review
  package to (`scripts/review-package --from BASELINE_FILE -- PATH...` prints
  the unique path it wrote; pass the task-start baseline and the cumulative
  union of files listed across the implementer and all fixer report entries)
- `[REVIEW_FILE]` — REQUIRED: a unique output path for this review cycle, such
  as `task-N-review-1.md`; never overwrite an earlier failed review

**Reviewer writes:** Full Spec Compliance verdict (✅/❌/⚠️), Strengths,
Issues (Critical/Important/Minor), and Task quality verdict to `[REVIEW_FILE]`

**Reviewer returns:** A short verdict summary and `[REVIEW_FILE]` path

A fix dispatch can address spec gaps and quality findings together;
re-review after fixes covers both verdicts.
