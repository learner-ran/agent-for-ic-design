---
name: experiment-reporter
description: use this skill when producing engineering reports for rtl generation experiments, including spec-to-rtl poc summaries, iteration logs, eda command results, generated artifact summaries, verification outcomes, limitations, and next-step recommendations.
---

# Experiment Reporter

## Purpose / 目的
为 RTL agent experiments 创建 human-readable engineering reports。

## Inputs to gather / 需要收集的输入
- spec file path
- module name
- generated artifacts
- commands run
- compile/sim/lint results
- debug iterations
- human interventions
- unresolved assumptions and risks

## Report style / 报告风格
- 中文为主，保留关键英文术语。
- MUST NOT oversell AI capability.
- Separate observed results from assumptions.
- Include exact pass/fail status.
- Mention what was not verified.

## Default structure / 默认结构
优先使用 `templates/experiment_report_template.md`。

## Required conclusion / 必要结论
结尾必须包含:
- what worked
- what failed or was uncertain
- what should be improved in spec/skill/agent flow
- next recommended benchmark module
