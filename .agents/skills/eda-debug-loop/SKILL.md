---
name: eda-debug-loop
description: use this skill when running eda commands and debugging compile, elaboration, lint, or simulation failures for generated or modified rtl and testbench files. trigger for vcs, verdi, dc, lint, make sim, make lint, log parsing, failure triage, and minimal fix iteration.
---

# EDA Debug Loop

## Purpose / 目的
运行 EDA commands，检查 logs，分类 failures，并执行 minimal fixes。

## Workflow / 工作流
1. 运行 requested Makefile target，通常是 `make sim`。
2. 有 current experiment `logs/` 时，capture or inspect logs。
3. Classify the failure:
   - compile syntax error
   - elaboration/interface mismatch
   - testbench bug
   - RTL functional bug
   - assertion failure
   - environment/tool/license issue
4. Propose a minimal fix。
5. 只修改 necessary files。
6. Re-run the smallest failing command。
7. Record iteration result。

## Rules / 规则
- MUST NOT mask failures by deleting checks or weakening scoreboards.
- Debug 过程中不要 expand scope。
- 如果问题是 environment/license/tool setup，必须清楚报告并停止修改 RTL。
- Prefer fixing root cause，而不是添加 delays 或 race-prone TB hacks。

## Final debug summary / 最终 debug 摘要
必须包含:
- command run
- failure symptom
- root cause
- files changed
- rerun result
- remaining risks
