# MCP Setup Notes

MCP 对这个 scaffold 是 optional，不是第一阶段的必要依赖。

## First-stage recommendation / 第一阶段建议
第一阶段直接使用 Makefile 和 shell commands 调用 EDA tools。不要在初版里为 VCS/DC/Verdi 构建 MCP servers。

## MCP is useful later for / 后续适合接入 MCP 的场景
- internal design guidelines
- protocol specifications
- reusable IP documentation
- verification methodology docs
- regression database queries
- issue tracker / review system integration

## Keep core skills domain-agnostic / 保持核心 skill 通用
如果未来 MCP 提供 NPU docs，应由 experiment 或 prompt 显式引用，不应 baked into `spec-planner` 或 `rtl-workflow`。
