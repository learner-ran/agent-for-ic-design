# int8_dot_acc RTL Implementation Plan

## 1. Spec summary / 需求摘要
`int8_dot_acc` implements a single-lane NPU-style signed int8 dot-product accumulator. One transaction starts with a legal `start_valid_i/start_ready_o` handshake and a nonzero `cfg_len_i`. The module then accepts exactly `cfg_len_i` activation/weight pairs through `in_valid_i/in_ready_o`, accumulates signed int8 x signed int8 products into a signed int32 accumulator with wrap-around behavior, and returns one signed int32 result through `out_valid_o/out_ready_i`.

The approved spec is `experiments/001_int8_dot_acc/spec/int8_dot_acc_spec.md` with `Status: frozen for implementation`.

## 2. Interface table / 接口表
| Signal | Dir | Width | Meaning | Notes |
|---|---:|---:|---|---|
| `clk_i` | input | 1 | rising-edge clock | single clock domain |
| `rst_ni` | input | 1 | active-low reset | synchronous |
| `start_valid_i` | input | 1 | start command valid | command handshake |
| `start_ready_o` | output | 1 | start command ready | `IDLE && cfg_len_i != 0` |
| `cfg_len_i` | input | `LEN_WIDTH` | transaction length | latched on `start_fire` |
| `act_i` | input | 8 | signed int8 activation | sampled on `in_fire` |
| `weight_i` | input | 8 | signed int8 weight | sampled on `in_fire` |
| `in_valid_i` | input | 1 | input pair valid | input handshake |
| `in_ready_o` | output | 1 | input pair ready | high in `ACCUM` |
| `out_valid_o` | output | 1 | result valid | high in `OUT` |
| `out_ready_i` | input | 1 | result ready | output handshake |
| `result_o` | output | 32 | signed int32 result | stable in `OUT` |
| `busy_o` | output | 1 | transaction active | high in `ACCUM` or `OUT` |
| `done_o` | output | 1 | registered completion pulse | one cycle after sampled `out_fire` |

## 3. Parameters / 参数
| Parameter | Default | Plan |
|---|---:|---|
| `LEN_WIDTH` | 16 | Use for `cfg_len_i`, `len_q`, and `count_q`; require `LEN_WIDTH >= 1` by parameter documentation |
| `ACC_WIDTH` | 32 | Keep fixed for this experiment; implement result and accumulator as signed 32-bit |

Legal `cfg_len_i` range is `1` to `2**LEN_WIDTH - 1`. Zero length is not accepted.

## 4. Ambiguities / 歧义点
- [blocking] None for first RTL/DV generation.
- [non-blocking] Future multi-lane packing is out of scope.
- [non-blocking] Future saturation/configurable overflow is out of scope.

## 5. Assumptions / 当前假设
- `rst_ni` is synchronous active-low reset.
- All inputs are synchronous to `clk_i`.
- `start_ready_o`, `in_ready_o`, `out_valid_o`, and `busy_o` may be simple combinational decodes of registered state.
- `done_o` is a registered pulse generated from `out_fire` sampled at the active clock edge.
- A new start command cannot be accepted in the same cycle as `out_fire`; it can be accepted after the state returns to `IDLE`.

## 6. Microarchitecture plan / 微架构计划
### State machine
Use a 3-state FSM:
- `IDLE`: no active transaction, no valid result pending.
- `ACCUM`: accepting input pairs and accumulating products.
- `OUT`: holding final result until downstream accepts it.

State transition rules:
- Reset -> `IDLE`.
- `IDLE` -> `ACCUM` on `start_fire`.
- `ACCUM` -> `OUT` on final `in_fire`, where `count_q == len_q - 1`.
- `OUT` -> `IDLE` on `out_fire`.
- Otherwise hold current state.

### Handshake decode
- `start_ready_o = (state_q == IDLE) && (cfg_len_i != '0)`.
- `start_fire = start_valid_i && start_ready_o`.
- `in_ready_o = (state_q == ACCUM)`.
- `in_fire = in_valid_i && in_ready_o`.
- `out_valid_o = (state_q == OUT)`.
- `out_fire = out_valid_o && out_ready_i`.
- `busy_o = (state_q != IDLE)`.

### Registers
- `state_q`: FSM state.
- `len_q[LEN_WIDTH-1:0]`: latched nonzero transaction length.
- `count_q[LEN_WIDTH-1:0]`: number of accepted samples before the current `in_fire`.
- `acc_q signed [31:0]`: current accumulated sum.
- `result_q signed [31:0]`: final result held through `OUT`.
- `done_q`: registered one-cycle completion pulse.

### Counter and terminal-count behavior
- On reset: `count_q = 0`, `len_q = 0`.
- On `start_fire`: `len_q = cfg_len_i`, `count_q = 0`, `acc_q = 0`.
- During `ACCUM` without `in_fire`: no counter or accumulator change.
- During `ACCUM` with non-final `in_fire`: `count_q = count_q + 1`, `acc_q = acc_q + product_ext_s32`.
- During `ACCUM` with final `in_fire` (`count_q == len_q - 1`): compute `sum_next = acc_q + product_ext_s32`, latch `result_q = sum_next`, optionally latch `acc_q = sum_next` for observability, and transition to `OUT`.
- No input pair is accepted once final count has fired.

### Arithmetic implementation
- Treat `act_i` and `weight_i` as signed two's complement int8.
- Explicitly sign-extend each operand before multiplication:
  - `act_s16 = {{8{act_i[7]}}, act_i}`
  - `weight_s16 = {{8{weight_i[7]}}, weight_i}`
- Compute signed 16-bit product from the extended operands. The int8 product range fits in signed 16 bits.
- Explicitly sign-extend product to 32 bits before accumulation:
  - `product_ext_s32 = {{16{product_s16[15]}}, product_s16}`
- Accumulation uses signed 32-bit two's complement wrap-around. No saturation, rounding, or clamp logic.

### Reset behavior
On synchronous active-low reset:
- `state_q = IDLE`
- `len_q = 0`
- `count_q = 0`
- `acc_q = 0`
- `result_q = 0`
- `done_q = 0`

### Output behavior
- `result_o = result_q`.
- `result_q` only changes on final `in_fire` or reset.
- While `out_valid_o && !out_ready_i`, FSM remains in `OUT`; `result_q`, `out_valid_o`, and `busy_o` remain stable.
- On `out_fire`, next state is `IDLE` and `done_q` pulses for one cycle.

## 7. Verification plan / 验证计划
### Directed tests
- Reset defaults: after reset release, check idle state behavior, `out_valid_o = 0`, `busy_o = 0`, `done_o = 0`, and zero-length command not ready.
- Illegal zero length: hold `cfg_len_i = 0` with `start_valid_i = 1`; verify no `start_fire`, no busy, no result.
- Length 1: one input pair immediately produces the expected result in `OUT`.
- Mixed-sign multi-sample transaction: compare against golden model.
- Upstream stalls: insert gaps with `in_valid_i = 0`; verify accumulator only updates on `in_fire`.
- Output backpressure: hold `out_ready_i = 0`; verify `out_valid_o`, `result_o`, and `busy_o` remain stable, and `done_o` does not pulse until `out_fire`.
- Back-to-back transactions: verify no state leakage between transactions.
- Ignored command while busy: assert `start_valid_i` during `ACCUM` and `OUT`; verify no new command is accepted.
- Ignored input outside accumulation: assert `in_valid_i` before start and during `OUT`; verify no consumption.
- Extreme values: include `-128 * -128`, `-128 * 127`, `127 * 127`, and mixed values.
- Wrap-around: choose a sequence that overflows signed int32 and verify two's complement wrap.

### Random tests
- Use deterministic default seed and print seed.
- Random legal lengths over a bounded simulation range, e.g. 1 to 64 for default regression.
- Random signed int8 activation/weight values.
- Random input stalls and output stalls.
- Random back-to-back transaction spacing.

### Scoreboard / golden model
- Golden model tracks only accepted pairs (`in_fire`), not raw valid cycles.
- Use signed integer arithmetic with explicit 32-bit mask/wrap to match RTL.
- Queue one expected result per accepted command; compare when `out_fire` occurs.

### Assertions
- `result_o` stable while `out_valid_o && !out_ready_i`.
- `out_valid_o` stable while stalled in `OUT`.
- `done_o` is never high for more than one cycle.
- `start_fire` never occurs while `busy_o`.
- `in_fire` occurs only in `ACCUM`.
- Accepted input count never exceeds `len_q`.
- `cfg_len_i == 0` never fires a start command.

## 8. Plan artifact / Plan 产物
- `experiments/001_int8_dot_acc/plan/int8_dot_acc_rtl_plan.md`

## 9. Implementation files / 后续文件
The next implementation stage would create or modify:
- `experiments/001_int8_dot_acc/rtl/int8_dot_acc.sv`
- `experiments/001_int8_dot_acc/tb/tb_int8_dot_acc.sv`
- `experiments/001_int8_dot_acc/sva/int8_dot_acc_sva.sv` if assertions are kept in a bind file
- `experiments/001_int8_dot_acc/Makefile` if no suitable experiment-local simulation target exists

This planning stage does not create RTL, TB, SVA, Makefile, scripts, reports, or logs.

## 10. Handoff / 下一步
- The plan is ready for `systemverilog-rtl-generator` and `dv-testbench-generator`.
- Before RTL/DV generation, confirm that the zero-length behavior and registered `done_o` timing in the frozen spec are acceptable.
- Small implementation risks to review during RTL generation:
  - SystemVerilog signed multiplication width and casts.
  - Off-by-one terminal count for `cfg_len_i == 1`.
  - Ensuring `done_o` pulse timing matches TB assertions.
  - Result stability during output backpressure.

