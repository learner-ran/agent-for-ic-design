---
name: dv-testbench-generator
description: use this skill when generating or editing digital verification artifacts for rtl modules, including self-checking systemverilog testbenches, golden models, scoreboards, monitors, drivers, directed tests, random tests, and optional sva protocol assertions.
---

# DV Testbench Generator

## Purpose / 目的
为 RTL modules 创建 practical、self-checking verification collateral。

## Required behavior / 必需行为
- 读取 spec、RTL 和 approved plan。
- 在 current experiment 的 `tb/` 下生成 TB；必要时在 `sva/` 下生成 assertions。
- 对 arithmetic 或 transaction-based behavior，尽量使用 golden/reference model。
- 包含 directed tests 和 reproducible random tests。
- 打印清晰的 PASS/FAIL messages。
- Random tests 必须 seeded，并 report the seed。

## Directed test checklist / 定向测试清单
- reset behavior
- single transaction or minimal operation
- multiple operations
- boundary values
- protocol stalls/backpressure if applicable
- completion or done behavior
- invalid or ignored control behavior if specified

## Assertions to consider / 可考虑的断言
- reset output expectations
- stable output while stalled
- no overflow/underflow when applicable
- legal state transitions
- grant onehot/onehot0 for arbiters
- no transaction loss or duplication for queues/streams

## Do not / 禁止事项
- MUST NOT weaken tests to make RTL pass.
- 当用户只要求 TB 时，MUST NOT change RTL，除非发现并报告了 clear RTL bug。
