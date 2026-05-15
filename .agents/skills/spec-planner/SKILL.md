---
name: spec-planner
description: use this skill when converting a digital ic frontend specification into a structured rtl implementation plan. trigger for tasks involving module specs, ambiguous requirements, interface definition, reset assumptions, protocol semantics, microarchitecture planning, corner cases, verification strategy, or preparing a plan before generating systemverilog rtl or testbench files.
---

# Spec Planner

## Purpose / 目的
把已存在的 approved/frozen structured spec 转换为可实现、可验证、可审查的 RTL plan。若用户只有模糊需求、draft spec、或没有 approved/frozen spec，应先使用 `requirement-to-spec`。该 skill 只输出 plan；需要文件产物时写入 `plan/<module>_rtl_plan.md`，不直接写 RTL/TB/SVA，也不运行 EDA。

## Entry gate / 入口门控
Planning 之前必须确认以下条件之一为真:
- spec metadata 写明 `Status: frozen for implementation`；或
- 用户在当前对话中明确说明 provided spec is approved/frozen for implementation。

如果输入是 vague requirement、`*.draft.md`、`Status: draft`、`Status: under review` 或 unapproved spec，必须 stop，并 route to `requirement-to-spec` 或 spec review/freeze。

Planning 不允许时，使用以下 blocked response:

```text
Blocked: current input is a vague requirement, draft spec, or unapproved spec.
Next required action: generate/revise the structured spec draft and wait for explicit user approval.
RTL planning and implementation are not allowed until the spec is frozen for implementation.
```

## Workflow / 工作流
1. 先确认上面的 entry gate。
2. 读取 target approved/frozen spec 和 AGENTS.md。
3. 提取 objective、scope、interface、parameters、clock/reset、protocol、behavior、deliverables。
4. 在 implementation 之前识别 ambiguity。
5. 只有 low-risk ambiguity 才能转成 explicit assumption；否则必须 ask the user 或 mark as open。
6. 输出 microarchitecture plan 和 verification plan；需要落盘时使用 `plan/<module>_rtl_plan.md`。
7. 列出下一阶段 would be created or modified 的 files。

## Must not do / 禁止事项
- MUST NOT write or modify RTL, TB, SVA, Makefile, scripts, or reports.
- MUST NOT run compile, simulation, lint, or debug commands.
- 当 blocking ambiguity 影响 interface、reset、protocol semantics、arithmetic behavior 或 verification pass/fail 时，MUST NOT proceed。
- MUST NOT hide blocking ambiguity as a non-blocking assumption.

## Required output format / 必需输出格式

```markdown
# Spec Planning Result

## 1. Spec summary / 需求摘要

## 2. Interface table / 接口表
| Signal | Dir | Width | Meaning | Notes |
|---|---:|---:|---|---|

## 3. Parameters / 参数

## 4. Ambiguities / 歧义点
- [blocking] ...
- [non-blocking] ...

## 5. Assumptions / 当前假设

## 6. Microarchitecture plan / 微架构计划

## 7. Verification plan / 验证计划
- Directed tests
- Random tests
- Assertions

## 8. Plan artifact / Plan 产物
- plan/<module>_rtl_plan.md

## 9. Implementation files / 后续文件
- rtl/...
- tb/...
- sva/...

## 10. Handoff / 下一步
- Required approvals or clarifications before RTL/DV generation
- Whether the plan is ready for `systemverilog-rtl-generator` and `dv-testbench-generator`
```

## Quality bar / 质量标准
- 不要 hide ambiguity。
- 如果输入是 vague requirement，而不是 structured spec，必须 stop and route to `requirement-to-spec`。
- 如果输入是 draft 或 unapproved spec，必须 stop，并要求 review/freeze before planning。
- counters 必须 specify exact terminal count and off-by-one behavior。
- arithmetic 必须 specify signedness, bit growth, truncation, saturation, rounding, or wrap behavior。
- valid-ready 必须 define fire conditions and stall behavior。
- reset 必须 specify polarity and sync/async behavior。
