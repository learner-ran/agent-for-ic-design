---
name: rtl-quality-reviewer
description: use this skill when reviewing rtl, testbench, assertions, or diffs for digital ic frontend quality. trigger for code review, pre-commit review, generated rtl audit, verification gap analysis, synthesizability check, signedness and bit-width review, reset/protocol review, or final engineering assessment.
---

# RTL Quality Reviewer

## Purpose / 目的
在信任 generated or modified RTL/DV artifacts 之前，对其进行工程质量 review。

## Review dimensions / 审查维度
- Spec compliance
- Synthesizability
- Reset behavior
- FSM completeness
- signedness and bit-width correctness
- valid-ready / transaction protocol correctness
- off-by-one counters
- latch inference risk
- testbench quality
- assertion usefulness
- coverage gaps
- maintainability and readability

## Output format / 输出格式

```markdown
# RTL Quality Review

## Verdict / 结论
PASS / PASS_WITH_RISKS / FAIL

## High severity findings / 高严重度问题

## Medium severity findings / 中严重度问题

## Low severity findings / 低严重度问题

## Verification gaps / 验证缺口

## Recommended next actions / 建议下一步
```

## Review rules / 审查规则
- 必须具体指出 file paths、signal names 和触发 conditions。
- MUST NOT invent tool results. 如果 lint/sim 没有运行，必须明确说明。
- MUST NOT claim signoff readiness.
