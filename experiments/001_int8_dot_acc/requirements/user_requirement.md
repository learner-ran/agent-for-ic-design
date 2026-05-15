# User Requirement

## Original request / 原始需求
This is a new independent task.

我想做一个偏 NPU compute datapath 的小模块，用来作为 RTL Codex Agent 的第一个实验。模块大概是：每拍输入一组 int8 activation 和 int8 weight，做 signed multiply-accumulate，累计指定长度后输出一个 int32 dot-product result。

希望模块有基本的 start/busy/done 控制，并且输入输出最好用 valid-ready handshake。

