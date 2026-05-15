# Optional Domain Profile: NPU / AI Accelerator

只有当 target module 明确是 NPU 或 AI accelerator block 时，才使用这个 profile。

## Common module categories / 常见模块类型
- MAC / dot-product datapath
- PE lane / PE array slice
- quantization / requantization
- activation function unit
- tensor address generator
- SRAM bank scheduler
- weight/activation buffer controller

## Common review hotspots / 常见审查热点
- signed int8/int16 multiplication
- accumulator bit growth
- saturation vs wrap-around
- rounding mode
- valid-ready backpressure
- tile loop counters
- off-by-one at tensor boundaries
- alignment and lane packing

除非用户明确要求，MUST NOT 将该 profile 用于 generic FIFO、arbiter、CSR 或 non-NPU modules。
