---
name: systemverilog-rtl-generator
description: use this skill when generating or editing synthesizable systemverilog rtl for digital ic frontend modules. trigger for tasks that ask for rtl implementation, module creation, fsm/datapath/control logic, arithmetic blocks, valid-ready interfaces, fifo/arbiter/register blocks, or fixing rtl code while preserving synthesis-safe style.
---

# SystemVerilog RTL Generator

## Purpose / 目的
根据 approved plan 生成或修改 synthesizable SystemVerilog RTL。

## Required behavior / 必需行为
- 读取 spec、approved plan、AGENTS.md，以及已有 RTL。
- 除非 explicit approval，否则 preserve interfaces。
- 只在 current experiment 的 `rtl/` 下写 synthesizable RTL。
- Arithmetic 必须使用 explicit signedness and bit-widths。
- 使用 `always_ff` 和 `always_comb`。
- Combinational logic 必须 provide default assignments。
- MUST NOT include testbench constructs in RTL.

## Implementation checklist / 实现检查清单
- Module header matches spec exactly.
- Parameters 有合理 defaults，并被 consistent use。
- Reset behavior matches spec.
- State machines 有 legal reset state 和 complete transitions。
- Handshake logic 能处理 stalls 和 simultaneous input/output events。
- Arithmetic behavior 必须说明 overflow 是 wraps、saturates，还是 out of scope。
- No latch inference.

## Output expectation / 输出要求
Editing 后 summarize:
- files created/modified
- key microarchitecture choices
- signedness/bit-width decisions
- assumptions carried from the plan
- verification commands that should be run next
