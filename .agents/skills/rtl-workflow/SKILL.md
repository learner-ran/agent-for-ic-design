---
name: rtl-workflow
description: use this skill to orchestrate an end-to-end digital ic frontend workflow from vague requirement or approved spec to rtl, testbench, eda simulation, debug, quality review, and experiment report. trigger when the user asks to run or design a codex rtl agent workflow, generate spec or rtl from requirements, produce rtl plus tb, run vcs or other eda tools, or perform a complete engineering poc.
---

# RTL Workflow

## Purpose / 目的
协调通用的 requirement-to-spec-to-RTL/DV/EDA/debug/report flow。该 skill 是 top-level workflow controller，需要根据阶段调用对应的 specialized skills。

## Stage gate responsibility / 阶段门控责任
`rtl-workflow` 是完整流程的 gatekeeper。它必须识别 current stage，选择 next legal action，并阻断 illegal transitions。

```text
Stage 0: vague requirement
Stage 1: structured spec draft
Stage 2: spec review / revision
Stage 3: frozen spec
Stage 4: RTL implementation plan (`plan/<module>_rtl_plan.md`)
Stage 5: RTL/TB/SVA generated
Stage 6: EDA simulation/debug
Stage 7: RTL quality review
Stage 8: experiment report
```

## End-to-end flow / 端到端流程
1. **Intake**: 判断输入是 vague requirement、draft spec、frozen spec，还是已有 RTL/DV artifact。
2. **Requirement-to-spec**: 如果没有 approved spec，使用 `requirement-to-spec` 创建 `spec/<module>_spec.draft.md`，列出 blocking questions，并等待 user review。
3. **Freeze spec**: 用户明确批准后，将 draft freeze 为 `spec/<module>_spec.md`，并标记 `Status: frozen for implementation`。
4. **Plan**: 使用 `spec-planner` 解析 frozen spec，只输出 plan-only result；需要落盘时写入 `plan/<module>_rtl_plan.md`。
5. **Approve assumptions**: 如果 ambiguity 是 blocking，停止并要求 clarification；如果不是 blocking，明确记录 assumptions。
6. **Implement RTL**: 使用 `systemverilog-rtl-generator` 生成 synthesizable RTL。
7. **Implement DV**: 使用 `dv-testbench-generator` 生成 self-checking TB 和 optional SVA。
8. **Run EDA**: 优先使用 Makefile targets，通常是 `make sim`。
9. **Debug**: compile/sim failure 交给 `eda-debug-loop`，只做 minimal fixes。
10. **Review**: 对 generated or modified artifacts 使用 `rtl-quality-reviewer`。
11. **Report**: 使用 `experiment-reporter` 创建 engineering report。

## Entry point detection / 入口判断
- Vague or informal module request: Stage 0。只能 route to `requirement-to-spec`。
- Existing `*.draft.md` spec 或 `Status: draft` / `Status: under review`: Stage 1/2。只能 review/revise draft；不能 plan 或 implement。
- Spec 标记为 `Status: frozen for implementation`，或用户明确说明 current spec is approved/frozen: Stage 3。route to `spec-planner`。
- 已有 `plan/<module>_rtl_plan.md` 或等价 RTL implementation plan，且无 blocking ambiguity: Stage 4。route to RTL/DV generation。
- 已生成 RTL/TB/SVA 但无 verification result: Stage 5。运行 smallest relevant EDA command。
- Compile/simulation/lint failure 或 log: Stage 6。route to `eda-debug-loop` 做 minimal fixes。
- Passing generated artifacts: Stage 7/8。route to `rtl-quality-reviewer` 和 `experiment-reporter`。

## Allowed transitions / 允许跳转
- Stage 0 -> Stage 1: generate a structured spec draft。
- Stage 1/2 -> Stage 3: 只有 explicit user approval 后才能 freeze。
- Stage 3 -> Stage 4: 生成 plan-only RTL implementation plan，推荐保存为 `plan/<module>_rtl_plan.md`。
- Stage 4 -> Stage 5: blocking ambiguities 解决或被用户明确接受后，生成 RTL/TB/SVA。
- Stage 5 -> Stage 6: 有 Makefile target 时通过 Makefile 运行 compile/simulation/lint。
- Stage 6 -> Stage 5/7: apply minimal debug fixes，然后 rerun verification；通过后进入 review。
- Stage 7 -> Stage 8: review findings 和 verification status 明确后写 experiment report。

## Blocked transitions / 阻断跳转
- MUST NOT generate RTL/TB/SVA from a vague requirement.
- MUST NOT run `spec-planner` on a draft, under-review, or unapproved spec.
- MUST NOT generate RTL/TB/SVA without `plan/<module>_rtl_plan.md` or an equivalent approved RTL implementation plan.
- MUST NOT hide blocking ambiguity as an assumption.
- MUST NOT mark work as tool-verified unless the relevant command has actually passed.

When blocked, respond with / 被阻断时使用:

```text
Blocked: current input is a vague requirement, draft spec, or unapproved spec.
Next required action: generate/revise the structured spec draft and wait for explicit user approval.
RTL planning and implementation are not allowed until the spec is frozen for implementation.
```

## User approval points / 用户批准点
- Freeze spec 需要 explicit user approval。
- 跳过 blocking ambiguity 需要 explicit user clarification or acceptance。
- Planning 之后进入 implementation，需要 user-approved plan，或用户明确授权按当前 listed plan and assumptions 继续。

## Operating rules / 操作规则
- 输入是 vague requirement 时，不能跳过 `requirement-to-spec`。
- 输入是 draft 或 under-review spec 时，不能跳过 freeze approval。
- Non-trivial generation 不能跳过 planning step。
- 优先使用 Makefile targets，而不是 ad-hoc tool commands。
- 所有 generated files 默认必须位于 current experiment；只有用户明确要求时才使用 other requested workspace。
- 不要 overfit 到任何单一 domain；domain context 应属于 spec。
- Implementation work 的 final answer 必须说明 changed files、commands run、pass/fail status、remaining risks、suggested next checks。

## Completion criteria / 完成标准
任务只有在以下任一条件满足时才算完成:
- requested spec draft 已交付，并包含 review questions；或
- requested plan 已交付，并包含 ambiguities 和 verification plan；或
- RTL/DV files 已生成，且 requested verification command 已通过；或
- verification failed，但 logs、root cause、attempted fixes、remaining blockers 已清楚报告。
