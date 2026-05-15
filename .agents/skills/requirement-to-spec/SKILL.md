---
name: requirement-to-spec
description: use this skill when the user provides a vague, informal, or high-level digital ic frontend module requirement and wants to generate, review, revise, and freeze a structured implementation spec before rtl planning or systemverilog generation. trigger before spec-planner when no approved spec exists, when the user asks to turn an idea into a spec, or when requirement ambiguity must be constrained.
---

# Requirement To Spec

## Purpose / 目的
把用户的模糊 module requirement 转换成可 review、可修改、可冻结的 structured RTL spec。该 skill 是 RTL 工作流的最前置阶段，必须先于 `spec-planner`、RTL generation、TB generation。

## Core rule / 核心规则
MUST NOT generate RTL from a vague requirement. 必须先 create/update spec draft，暴露 ambiguities，等待 user review；只有 spec 被 approved 或明确标记为 frozen 后，才能进入后续阶段。

## Stage boundary / 阶段边界
该 skill 只负责 Stage 0 到 Stage 2:
- Stage 0: vague requirement
- Stage 1: structured spec draft
- Stage 2: spec review / revision

它可以 create/update `spec/<module>_spec.draft.md`。MUST NOT create RTL, TB, SVA, or an RTL implementation plan。没有 explicit user approval 时，MUST NOT freeze spec。

## Workflow / 工作流
1. **Requirement intake**
   - 读取 user requirement、AGENTS.md、可选 domain profile，以及已有 requirement/spec draft。
   - 识别 module category: datapath, control/FSM, buffer/FIFO, arbiter, register/CSR, address generator, protocol adapter, memory wrapper, arithmetic unit, or other。

2. **Generate spec draft**
   - 在 current experiment 的 `spec/` 下，使用下方 spec structure 创建或更新 `spec/<module>_spec.draft.md`。
   - 使用 bilingual style: 中文解释 + English key terms。
   - assumptions 必须显式记录，并标记为 `[assumption]`。
   - unknowns 必须显式记录，并标记为 `[open]`。

3. **Review questions**
   - 为用户输出简短 review checklist。
   - 区分 blocking questions 和 non-blocking questions。
   - 不要无限追问；优先提出会影响 RTL behavior 或 verification 的问题。

4. **Revise spec**
   - 用户给出 review comments 后，更新 draft。
   - 维护 `Revision history` section。
   - 将已解决的 `[open]` items 转换成 concrete rules。

5. **Freeze spec**
   - 只有用户明确 approve 后，才能 create/rename 为 `spec/<module>_spec.md`。
   - 标记 `Status: frozen for implementation`。
   - Freeze 后 hand off to `spec-planner`，进入 implementation planning。

## Must not do / 禁止事项
- MUST NOT generate or modify files under `rtl/`, `tb/`, or `sva/`.
- MUST NOT produce an RTL implementation plan.
- MUST NOT treat silence, partial agreement, or unresolved blocking questions as approval to freeze.
- 当 spec 仍为 `draft`、`under review`，或仍有 unresolved `[blocking]` items 时，MUST NOT route to `spec-planner`。

## Handoff criteria / 交接条件
只有同时满足以下条件，才允许 handoff to `spec-planner`:
- spec file 是 `spec/<module>_spec.md`；
- metadata 写明 `Status: frozen for implementation`；
- blocking questions 已解决，或用户明确接受 remaining risk；
- 用户明确批准 using the spec for implementation。

## Required spec structure / 必需 spec 结构
Use this structure unless the project already defines a stricter template:

```markdown
# <module_name> Spec

## 0. Metadata / 元信息
- Module name:
- Status: draft | under review | frozen for implementation
- Owner / Reviewer:
- Created from requirement:
- Revision:

## 1. Goal / 目标

## 2. Scope / 范围
### In scope / 本次包含
### Out of scope / 本次不包含

## 3. Use scenario / 使用场景

## 4. Interface / 接口
| Signal | Dir | Width | Clock domain | Description | Notes |
|---|---:|---:|---|---|---|

## 5. Parameters / 参数
| Parameter | Default | Legal range | Description |
|---|---:|---|---|

## 6. Clock and reset / 时钟与复位
- Clock:
- Reset polarity:
- Reset type: synchronous | asynchronous
- Reset state:

## 7. Functional behavior / 功能行为

## 8. Protocol semantics / 协议语义
- valid-ready handshake if applicable
- fire condition
- stall/backpressure behavior
- ordering rule
- accepted/ignored conditions

## 9. Datapath and arithmetic rules / 数据通路与算术规则
- signedness
- bit growth
- truncation/extension
- saturation/wrap/rounding
- overflow behavior

## 10. Control behavior / 控制行为
- FSM or transaction lifecycle
- start/busy/done semantics if applicable
- legal/illegal command behavior

## 11. Corner cases / 边界条件

## 12. Verification requirements / 验证要求
- Directed tests
- Random tests
- Scoreboard / golden model
- Assertions
- Coverage ideas

## 13. Deliverables / 交付物

## 14. Open issues / 未决问题
- [blocking] ...
- [non-blocking] ...

## 15. Revision history / 修订记录
```

## Ambiguity policy / 歧义处理策略
按以下等级 classify ambiguity:
- `[blocking]`: 影响 interface、state、arithmetic result、protocol semantics、reset behavior 或 verification pass/fail。必须 stop before implementation。
- `[non-blocking]`: 可以带着明确 stated assumption 继续。
- `[nice-to-have]`: 对 future extension 有帮助，但 current module 不强制要求。

## Quality bar / 质量标准
Generated spec draft 只有包含以下内容才算 acceptable:
- explicit signal directions and widths；如果缺失 width，必须有 open question；
- reset polarity and sync/async behavior；如果缺失，必须有 blocking question；
- 涉及 streaming 或 request/response 时，必须有 exact handshake/fire semantics；
- datapath modules 必须有 exact arithmetic signedness and bit growth；
- corner cases and verification requirements；
- 清晰的 assumptions and open questions 列表。

## Output format in chat / 对话输出格式
When creating the first draft, respond with:

```markdown
# Requirement-to-Spec Result

## Generated files / 生成文件
- spec/<module>_spec.draft.md

## Key assumptions / 关键假设
- ...

## Blocking questions for review / 需要 review 的阻塞问题
1. ...

## Non-blocking questions / later decisions
1. ...

## Required approval before implementation / 实现前必须批准
- Spec must be reviewed and explicitly approved/frozen by the user.

## Next step / 下一步
请 review spec draft。确认或修改 blocking questions 后，明确批准 freeze spec，才能进入 spec-planner。
```
