# SystemVerilog RTL Rules / RTL 编码规则

## RTL subset / RTL 子集
- `rtl/` 下的 RTL files 必须是 synthesizable SystemVerilog。
- 除非确实需要 net type，否则 signals 使用 `logic`。
- 一致使用 `always_ff` 和 `always_comb`。
- RTL 中 MUST NOT 使用 testbench-only constructs。

## Sequential logic / 时序逻辑
- 只使用 non-blocking assignments。
- Reset behavior 必须 explicit。
- 避免在一个 hard-to-review block 中混合 unrelated state updates。

## Combinational logic / 组合逻辑
- 在 `always_comb` 开头提供 default assignments。
- 避免 incomplete case/if ladders。
- 只有语义确实需要时，才使用 `unique case` 或 `priority case`。

## Arithmetic / 算术
- signed signals 必须 explicit declare。
- multiplication、accumulation、truncation、extension 使用 explicit casts。
- intentional overflow、saturation、wrap-around behavior 需要 comment 说明。

## Handshake interfaces / 握手接口
对于 valid-ready interfaces，按 transaction 语义分析:
- input fire: `in_valid && in_ready`
- output fire: `out_valid && out_ready`
- hold data stable while stalled
- avoid data loss and duplication

## Review hotspots / 审查热点
- off-by-one counters
- cfg length zero or one
- reset release behavior
- simultaneous push/pop or input/output fire
- output backpressure
- signed multiplication
- state transitions at completion
