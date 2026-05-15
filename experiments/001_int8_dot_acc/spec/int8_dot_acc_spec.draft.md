# int8_dot_acc Spec

## 0. Metadata / 元信息
- Module name: `int8_dot_acc`
- Status: draft
- Owner / Reviewer: user / Codex
- Created from requirement: `experiments/001_int8_dot_acc/requirements/user_requirement.md`
- Module category: NPU compute datapath, arithmetic unit
- Revision: v0.1

## 1. Goal / 目标
`int8_dot_acc` 是一个小型 NPU-style dot-product datapath module。模块在一次 transaction 中接收一串 signed int8 activation/weight pair，对每个 pair 执行 signed multiply-accumulate，并在累计指定长度后输出一个 signed int32 dot-product result。

目标是作为 RTL Codex Agent 的第一个 experiment：接口和行为应足够简单，但必须覆盖 valid-ready handshake、start/busy/done control、signed arithmetic、counter boundary、output backpressure 等典型 RTL/DV review hotspot。

## 2. Scope / 范围
### In scope / 本次包含
- 单 lane signed int8 x signed int8 multiply-accumulate。
- 每个 accepted input pair 贡献一个 product。
- 每个 transaction 输出一个 signed int32 result。
- `start_valid/start_ready` command handshake，用于启动一次 dot-product transaction。
- `in_valid/in_ready` streaming input handshake，用于输入 activation/weight pair。
- `out_valid/out_ready` output handshake，用于输出 result。
- `busy` status 和 `done` indication。
- Configurable dot-product length input, latched at transaction start。
- Self-checking verification requirements covering directed and random cases。

### Out of scope / 本次不包含
- 多 lane SIMD packing 或 parallel MAC。
- activation/weight buffer、SRAM interface、address generation、tile scheduler。
- quantization、requantization、rounding、clamp、ReLU 或 post-processing。
- AXI/AHB/APB 等标准 bus interface。
- CDC/RDC, DFT, power intent, timing closure, physical design。
- Saturating accumulator unless explicitly approved later。

## 3. Use scenario / 使用场景
- 上游 controller 发起一次 dot-product command，并提供 `cfg_len_i`。
- 模块进入 busy 状态后，上游 datapath 每拍尽可能提供一组 `act_i` 和 `weight_i`。
- 如果 output result 被下游 backpressure 阻塞，模块保持 result stable 并等待 `out_ready_i`。
- 该模块可作为更大 NPU PE lane 或 compute datapath 的最小 proof-of-concept block。

## 4. Interface / 接口
| Signal | Dir | Width | Clock domain | Description | Notes |
|---|---:|---:|---|---|---|
| `clk_i` | input | 1 | `clk_i` | rising-edge clock | |
| `rst_ni` | input | 1 | `clk_i` | active-low reset | [assumption], see open issue Q1 |
| `start_valid_i` | input | 1 | `clk_i` | command valid for starting one dot-product transaction | valid-ready command channel |
| `start_ready_o` | output | 1 | `clk_i` | module can accept start command | high when idle and no unconsumed result |
| `cfg_len_i` | input | `LEN_WIDTH` | `clk_i` | number of input pairs to accumulate for this transaction | latched on `start_fire`; legal range TBD |
| `act_i` | input | 8 | `clk_i` | signed int8 activation sample | sampled on `in_fire` |
| `weight_i` | input | 8 | `clk_i` | signed int8 weight sample | sampled on `in_fire` |
| `in_valid_i` | input | 1 | `clk_i` | input pair valid | valid-ready input channel |
| `in_ready_o` | output | 1 | `clk_i` | module can accept one input pair | high while accepting current transaction input |
| `out_valid_o` | output | 1 | `clk_i` | result valid | valid-ready output channel |
| `out_ready_i` | input | 1 | `clk_i` | downstream can accept result | |
| `result_o` | output | 32 | `clk_i` | signed int32 dot-product result | stable while `out_valid_o && !out_ready_i` |
| `busy_o` | output | 1 | `clk_i` | transaction in progress | excludes idle; exact behavior during output wait TBD |
| `done_o` | output | 1 | `clk_i` | transaction done indication | pulse timing TBD |

## 5. Parameters / 参数
| Parameter | Default | Legal range | Description |
|---|---:|---|---|
| `LEN_WIDTH` | 16 | >= 1 | Width of `cfg_len_i` and internal accepted-sample counter |
| `ACC_WIDTH` | 32 | fixed at 32 for this experiment | Width of accumulator and `result_o` |

## 6. Clock and reset / 时钟与复位
- Clock: single `clk_i`, all sequential state updates on rising edge。
- Reset polarity: [assumption] active-low reset `rst_ni`。
- Reset type: [assumption] synchronous reset。
- Reset state:
  - command channel idle: `start_ready_o = 1` after reset release。
  - `busy_o = 0`。
  - `done_o = 0`。
  - `in_ready_o = 0` until a legal start command is accepted。
  - `out_valid_o = 0`。
  - accumulator, counter, and `result_o` reset to zero for deterministic simulation。

## 7. Functional behavior / 功能行为
- A transaction starts when `start_fire = start_valid_i && start_ready_o`。
- On `start_fire`, module latches `cfg_len_i`, clears accumulator to zero, clears accepted-pair counter to zero, and enters input-accepting state。
- During an active transaction, each `in_fire = in_valid_i && in_ready_o` samples one `act_i` and one `weight_i` pair。
- For each accepted pair, module computes signed product `signed(act_i) * signed(weight_i)` and adds it to the accumulator。
- After exactly the configured number of accepted input pairs, module stops accepting input and presents the final accumulator value as `result_o` with `out_valid_o = 1`。
- A result transaction completes when `out_fire = out_valid_o && out_ready_i`。
- After the output result is accepted, module returns to idle and can accept the next start command。

## 8. Protocol semantics / 协议语义
- Command fire condition: `start_fire = start_valid_i && start_ready_o`。
- Input fire condition: `in_fire = in_valid_i && in_ready_o`。
- Output fire condition: `out_fire = out_valid_o && out_ready_i`。
- `cfg_len_i` is sampled only on `start_fire`; changes while busy are ignored。
- `act_i` and `weight_i` are sampled only on `in_fire`; changes while `in_valid_i && !in_ready_o` must not be consumed。
- When `out_valid_o && !out_ready_i`, `result_o` must remain stable。
- [assumption] `start_ready_o` is deasserted from accepted start until the current result has completed `out_fire`。
- [assumption] input order is preserved; output result corresponds to the most recent accepted start transaction。
- [assumption] only one transaction can be in flight; no command queueing。

## 9. Datapath and arithmetic rules / 数据通路与算术规则
- signedness:
  - `act_i` is signed 8-bit two's complement。
  - `weight_i` is signed 8-bit two's complement。
  - product is signed 16-bit two's complement before extension。
  - accumulator and result are signed 32-bit two's complement。
- bit growth:
  - product range is `[-128*128, 127*127] = [-16384, 16129]`。
  - product must be sign-extended to 32 bits before accumulation。
- truncation/extension:
  - product-to-accumulator conversion must use explicit sign extension or signed cast。
  - no rounding is used。
- saturation/wrap/rounding:
  - [assumption] accumulator uses signed 32-bit wrap-around if mathematical sum exceeds int32 range。
  - no saturation or clamp in this experiment。
- overflow behavior:
  - [open] Maximum supported `cfg_len_i` must be reviewed against int32 overflow expectations。
  - For guaranteed no-overflow mathematical accumulation, maximum length is implementation/verification dependent and should be constrained or overflow should be explicitly accepted。

## 10. Control behavior / 控制行为
- Transaction lifecycle:
  1. `IDLE`: waits for `start_fire`。
  2. `ACCUM`: accepts exactly `cfg_len_i` input pairs via `in_fire`。
  3. `OUT`: holds final result until `out_fire`。
  4. returns to `IDLE`。
- `busy_o` semantics:
  - [assumption] `busy_o = 1` from the cycle after `start_fire` until the result is accepted by `out_fire`。
  - [open] Alternative is to deassert `busy_o` once `out_valid_o` is raised; this affects software/control interpretation。
- `done_o` semantics:
  - [assumption] `done_o` is a one-cycle pulse on `out_fire`。
  - [open] Alternative is pulse when `out_valid_o` first rises, regardless of `out_ready_i`。
- Illegal or ignored command behavior:
  - `start_valid_i` while `start_ready_o = 0` is not accepted and has no effect。
  - `in_valid_i` while `in_ready_o = 0` is not accepted and has no effect。
  - [open] `cfg_len_i == 0` behavior is not finalized。

## 11. Corner cases / 边界条件
- Reset during idle, accumulation, and output wait。
- `cfg_len_i == 1`: first accepted pair is also the last pair。
- `cfg_len_i == 0`: [blocking] behavior must be defined before implementation。
- Upstream stalls: gaps in `in_valid_i` during accumulation。
- Downstream backpressure: `out_ready_i = 0` when result becomes valid。
- Simultaneous last `in_fire` and downstream ready not applicable if result is registered for a later output phase; exact latency may be decided during implementation planning after spec freeze。
- Extreme signed values:
  - `act_i = -128`, `weight_i = -128`。
  - `act_i = -128`, `weight_i = 127`。
  - mixed positive/negative products。
- Multiple back-to-back transactions。
- `start_valid_i` asserted while busy。
- Input valid asserted before start or after accumulation complete。
- Accumulator wrap-around if allowed by approved spec。

## 12. Verification requirements / 验证要求
- Directed tests / 定向测试:
  - reset defaults。
  - single transaction with `cfg_len_i = 1`。
  - multi-sample transaction with positive, negative, and mixed signs。
  - upstream input stalls。
  - output backpressure with result stability check。
  - back-to-back transactions。
  - ignored `start_valid_i` while busy。
  - ignored `in_valid_i` before start and after enough samples。
  - `cfg_len_i == 0` after behavior is resolved。
- Random tests / 随机测试:
  - reproducible seed。
  - random `cfg_len_i` over approved legal range。
  - random signed int8 activation/weight values。
  - random input stalls and output stalls。
- Scoreboard / golden model / 结果比较:
  - TB golden model computes signed integer sum of accepted pairs using 32-bit two's complement behavior matching approved overflow rule。
- Assertions / 断言:
  - `result_o` stable while `out_valid_o && !out_ready_i`。
  - no input accepted outside active accumulation。
  - no start accepted while busy or output pending。
  - `done_o` pulse width is one cycle after final approved semantics。
  - counter never accepts more than latched `cfg_len_i` samples。
- Coverage ideas / 覆盖点:
  - length 1, small lengths, maximum tested length。
  - all sign combinations。
  - output backpressure length greater than one cycle。
  - reset in each lifecycle state。

## 13. Deliverables / 交付物
After this draft is reviewed and explicitly frozen, expected later deliverables are:
- `plan/int8_dot_acc_rtl_plan.md`
- `rtl/int8_dot_acc.sv`
- `tb/tb_int8_dot_acc.sv`
- `sva/int8_dot_acc_sva.sv` if useful
- `logs/` compile/simulation logs
- `reports/int8_dot_acc_experiment_report.md`

No RTL, TB, SVA, or implementation plan is generated in this stage。

## 14. Open issues / 未决问题
- [blocking] Q1: Confirm reset convention: should `rst_ni` be active-low synchronous reset, active-low asynchronous reset, or another project convention?
- [blocking] Q2: Define legal `cfg_len_i` range. Is `cfg_len_i == 0` illegal/ignored, or should it produce a zero result transaction?
- [blocking] Q3: Confirm int32 overflow behavior. Should accumulation wrap in signed 32-bit two's complement, saturate, or should `cfg_len_i` be constrained so overflow cannot occur?
- [blocking] Q4: Confirm `done_o` timing. Should `done_o` pulse when result becomes valid, or when the result is accepted by `out_fire`?
- [blocking] Q5: Confirm `busy_o` behavior during output backpressure. Should `busy_o` remain high while `out_valid_o && !out_ready_i`?
- [non-blocking] Q6: Confirm preferred latency from last accepted input pair to `out_valid_o`. Draft allows implementation planning to choose a registered one-cycle transition.
- [non-blocking] Q7: Confirm whether `LEN_WIDTH = 16` is appropriate for the first experiment, or whether a smaller default such as 8 is preferred for simpler simulation.
- [nice-to-have] Q8: Should future versions support multiple lanes or packed input pairs?

## 15. Revision history / 修订记录
| Rev | Author | Change |
|---|---|---|
| v0.1 | Codex | Initial draft from vague NPU dot-product requirement |

