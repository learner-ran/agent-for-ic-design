# Requirement-to-Spec Workflow

真实工程入口通常不是完整 spec，而是模糊 module requirement。Agent 必须先把 requirement 结构化成 spec draft，并让人 review。

## Flow / 流程

```text
vague user requirement
  -> requirement-to-spec
  -> spec/<module>_spec.draft.md
  -> human review comments
  -> revised draft
  -> user approval
  -> spec/<module>_spec.md frozen
  -> spec-planner
  -> plan/<module>_rtl_plan.md
  -> RTL/TB/SVA generation
```

## Review gate / Review 门控

禁止从以下输入直接生成 RTL：
- 只有一句话需求；
- 没有 interface width；
- reset 行为不清楚；
- arithmetic signedness/bit growth 不清楚；
- protocol fire/stall 行为不清楚；
- expected output timing 不清楚。

## Naming / 命名

- `requirements/user_requirement.md`: 原始需求记录。
- `spec/<module>_spec.draft.md`: agent 生成的 spec 草案。
- `spec/<module>_spec.md`: review 后冻结的实现 spec。
- `plan/<module>_rtl_plan.md`: frozen spec 之后生成的 RTL implementation plan。
- `rtl/`、`tb/`、`sva/`: experiment-local RTL/DV artifacts。
