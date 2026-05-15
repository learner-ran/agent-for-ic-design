# RTL Codex Agent Scaffold

这是一个通用 digital IC frontend Codex agent 工作台，不绑定 NPU。NPU、DSP、bus fabric、SRAM controller 等都应作为具体 experiment 或 domain profile，而不是核心 skill 名称。

## Quick start / 快速开始

```bash
cd /home/ICer
# 解压本 scaffold 后：
cd rtl_codex_agent_scaffold
codex -m gpt-5.5
```

第一条建议 prompt，从模糊需求开始：

```text
This is a new independent task.
Use rtl-workflow and requirement-to-spec.
我要做一个 int8 dot-product accumulator：每拍输入 activation 和 weight，做 signed MAC，累计一定长度后输出 int32 result。请先生成 spec draft，不要写 RTL。
```

推荐先创建一个空 experiment：

```bash
scripts/new_experiment.sh 001_int8_dot_acc dot_acc
```

## Skill design / Skill 设计

核心 skills 全部是通用 RTL/DV/EDA 能力：

- requirement-to-spec
- spec-planner
- rtl-workflow
- systemverilog-rtl-generator
- dv-testbench-generator
- eda-debug-loop
- rtl-quality-reviewer
- experiment-reporter

## Experiment layout / 实验目录

真实任务默认放在 `experiments/<id>_<name>/` 下，framework 顶层目录只放 reusable infrastructure。

```text
experiments/<id>_<name>/
├── requirements/user_requirement.md
├── spec/<module>_spec.draft.md
├── spec/<module>_spec.md
├── plan/<module>_rtl_plan.md
├── rtl/
├── tb/
├── sva/
├── logs/
├── reports/
└── Makefile
```

新建 experiment 推荐使用:

```bash
scripts/new_experiment.sh 002_sync_fifo sync_fifo
```

## First experiment / 第一个实验

仓库默认不预置具体 experiment。真实工作流建议先用 `scripts/new_experiment.sh` 创建 experiment skeleton，然后从 `requirements/user_requirement.md` 或用户自然语言需求开始，由 `requirement-to-spec` 生成 `spec/*.draft.md`，review 后再冻结为 `spec/*.md`。
