# Verification Rules / 验证规则

## Testbench expectations / TB 期望
- Prefer self-checking testbenches。
- 打印清晰的 PASS/FAIL messages。
- mismatch 时 fail fast。
- Random tests 必须 record seed。
- 除非显式传入 seed，否则 testbench 应保持 deterministic。

## Golden model / 参考模型
对于 arithmetic 和 transaction-based designs，在 TB 中使用 simple behavioral golden model。

## Directed tests / 定向测试
包含 reset、single transaction、multiple transactions、boundary lengths、stalls/backpressure，以及 spec 指定时的 illegal or ignored operation behavior。

## Random tests / 随机测试
可行时使用 constrained random stimulus，并保持 reproducible。

## Assertions / 断言
当 protocol invariants 需要约束时，添加 SVA:
- stability under stall
- legal state transitions
- no overflow/underflow
- onehot/onehot0
- reset expectations
