# <module_name> Spec

## 0. Metadata / 元信息
- Module name: <module_name>
- Status: draft | under review | frozen for implementation
- Owner / Reviewer:
- Created from requirement:
- Revision: v0.1

## 1. Goal / 目标
[中文说明模块目标，关键英文术语保留。]

## 2. Scope / 范围
### In scope / 本次包含
- ...

### Out of scope / 本次不包含
- ...

## 3. Use scenario / 使用场景
- ...

## 4. Interface / 接口
| Signal | Dir | Width | Clock domain | Description | Notes |
|---|---:|---:|---|---|---|
| clk | input | 1 | clk | rising-edge clock | |
| rst_n | input | 1 | clk | active-low reset | specify sync/async |

## 5. Parameters / 参数
| Parameter | Default | Legal range | Description |
|---|---:|---|---|

## 6. Clock and reset / 时钟与复位
- Clock:
- Reset polarity:
- Reset type: synchronous | asynchronous
- Reset state:

## 7. Functional behavior / 功能行为
- ...

## 8. Protocol semantics / 协议语义
- valid-ready handshake if applicable
- fire condition
- stall/backpressure behavior
- ordering rule
- accepted/ignored conditions

## 9. Datapath and arithmetic rules / 数据通路与算术规则
- signedness:
- bit growth:
- truncation/extension:
- saturation/wrap/rounding:
- overflow behavior:

## 10. Control behavior / 控制行为
- FSM or transaction lifecycle:
- start/busy/done semantics if applicable:
- legal/illegal command behavior:

## 11. Corner cases / 边界条件
- ...

## 12. Verification requirements / 验证要求
- Directed tests / 定向测试:
- Random tests / 随机测试:
- Scoreboard / golden model / 结果比较:
- Assertions / 断言:
- Coverage ideas / 覆盖点:

## 13. Deliverables / 交付物
- plan/<module_name>_rtl_plan.md
- rtl/<module_name>.sv
- tb/tb_<module_name>.sv
- sva/<module_name>_sva.sv if useful
- reports/<module_name>_experiment_report.md

## 14. Open issues / 未决问题
- [blocking] ...
- [non-blocking] ...

## 15. Revision history / 修订记录
| Rev | Author | Change |
|---|---|---|
| v0.1 | codex | initial draft from requirement |
