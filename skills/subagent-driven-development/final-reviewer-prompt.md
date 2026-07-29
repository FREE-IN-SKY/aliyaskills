# Final Reviewer Prompt Template

Use this template after every task review is clean. It reviews all current
working-tree changes without relying on commits or mutating Git state.

```
Subagent (general-purpose):
  description: "Review all completed changes"
  prompt: |
    You are the final reviewer for all completed work in this plan.

    ## Requirements

    Read the implementation plan: [PLAN_FILE]
    Read the progress ledger: [LEDGER_FILE]

    ## Changes Under Review

    Read the workflow review package: [DIFF_FILE]
    It contains the changed-path list, summary, and full diff for all current
    changes made since this SDD run began, including files that became
    untracked. Treat it as the complete review input.

    This review is read-only. Do not run Git commands and do not mutate files,
    the index, HEAD, branches, worktrees, or repository state.

    Do not create a nested child agent or delegate this review to another
    agent. Root-controller delegation remains allowed and required; this rule
    only forbids subagents from creating further subagents. Perform this review
    directly in this dispatch.

    ## Test Evidence

    Read the task brief, task report, and task review report files named in
    the ledger. The briefs are the resolved requirements, including any
    `Controller Resolutions`. Treat report test results as claims to verify
    against the changed tests and implementation. Do not run the full suite
    unless the human explicitly requested it. Run a focused test only when a
    concrete doubt cannot be resolved by reading the artifacts; name the
    doubt and command.

    ## Prior Final-Review Cycle

    Prior findings: [PRIOR_FINDINGS_FILE_OR_NA]
    Final fix report: [FINAL_FIX_REPORT_FILE_OR_NA]

    On an initial final review, both values are `N/A`. On a re-review, read
    both files, verify the fix report's test evidence, and explicitly mark
    every prior Critical and Important finding as resolved or still open.

    ## Review

    Check whole-plan completeness, cross-task integration, correctness,
    regressions, error handling, maintainability, security, and whether tests
    verify real behavior. Cite file:line evidence for every finding.

    Categorize findings as Critical, Important, or Minor. Critical and
    Important findings block handoff.
    Read open Minor findings from the task review reports named in the ledger
    and state whether each should be fixed before handoff or deferred.

    ## Output Format

    ### Strengths
    ### Issues
    #### Critical
    #### Important
    #### Minor
    ### Assessment

    **Ready for human handoff:** [Yes | No]
    **Reasoning:** [1-2 sentences]
```

**Placeholders:**
- `[PLAN_FILE]` - full implementation plan
- `[LEDGER_FILE]` - durable progress ledger
- `[DIFF_FILE]` - package from
  `scripts/review-package --from RUN_BASELINE` with no path list
- `[PRIOR_FINDINGS_FILE_OR_NA]` - `N/A` for the initial review; otherwise the
  saved output from the previous final reviewer
- `[FINAL_FIX_REPORT_FILE_OR_NA]` - `N/A` for the initial review; otherwise the
  final fixer's changes and test-evidence report
