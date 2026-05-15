# RTL Codex Agent Architecture

## Goal / 目标
构建一个可复用的 Codex-based RTL engineering assistant，用于 digital IC frontend development。

该 agent 应支持:
- requirement-to-spec drafting and review
- spec clarification
- microarchitecture planning
- synthesizable SystemVerilog generation
- self-checking testbench generation
- optional SVA generation
- EDA compile/simulation debug loop
- quality review
- experiment reporting

## Layering / 分层

```text
RTL Codex Agent Workspace
├── AGENTS.md                 # global project behavior and rules
├── .codex/config.toml         # project-local default safety settings
├── .agents/skills/            # reusable skills
├── templates/                 # spec/report templates
├── references/                # glossary, rules, domain profiles
├── scripts/                   # deterministic helper scripts
├── docs/                      # architecture and workflow notes
└── experiments/               # individual tasks / benchmarks
```

## Experiment layout / 实验目录
真实 module artifacts 默认放在 experiment-local workspace 中，避免多个任务共享 top-level `rtl/`、`tb/`、`sva/` 造成污染。

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

Top-level `templates/`、`references/`、`scripts/`、`docs/` 是 framework infrastructure。除非用户明确要求 non-experiment workspace，真实 RTL/DV deliverables SHOULD live under `experiments/<id>_<name>/`。

## Why skills are generic / 为什么 skill 保持通用
核心 skill 命名有意避免 `npu-spec-planner` 这类 domain-specific name。`spec-planner` 应该能服务 FIFO、arbiter、PE lane、DMA block、CSR register bank、address generator、datapath arithmetic module 等多种模块。

Domain-specific context 应放在:
- requirement files and experiment specs
- `references/domain_profiles/*.md`
- user prompts
- 未来可选的 project-level `AGENTS.md` extensions

## Recommended flow / 推荐流程

```text
Vague module requirement
  ↓
requirement-to-spec
  ↓
spec draft review / revision
  ↓
frozen structured spec
  ↓
spec-planner
  ↓
plan/<module>_rtl_plan.md
  ↓
Human review / assumption approval
  ↓
systemverilog-rtl-generator + dv-testbench-generator
  ↓
make sim / make lint
  ↓
eda-debug-loop
  ↓
rtl-quality-reviewer
  ↓
experiment-reporter
```

## First-stage scope / 第一阶段适合范围
适合作为 first-stage modules:
- arithmetic datapath block
- simple valid-ready pipeline stage
- FIFO / queue
- arbiter
- register file
- address generator
- CSR block
- small controller FSM

第一阶段不建议直接做:
- full AXI master/slave
- multi-clock CDC blocks
- large DMA engines
- full UVM environment
- complete NPU/SoC subsystem
- signoff claims
