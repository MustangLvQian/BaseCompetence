---
id: EXP-20261022-0022
title: 任务的 token 用量必须写进任务日志，不能靠自觉
tags: [process, token, task-log, maintenance]
severity: medium
status: active
guard: G-0020
seen: 1
source: 复盘 token 数据：英创与 VoiceBuilder 的任务日志几乎全是「未知」
created: 2026-10-22
---

# 任务的 token 用量必须写进任务日志，不能靠自觉

**症状**：两个项目的任务日志里，token 消耗列几乎全是「未知」。规则里写了「开工记会话 ID、结束补填」，但没有任何机制保证执行，一次漏掉就永远缺数据。

**根因**：记录依赖人或 agent 的自觉，且 agent 无法在会话内取到自己的会话 ID，补填步骤又容易被跳过。

**规则**：
- 任务结束后，新开会话运行 `node tools/record-usage.cjs <任务ID>`，把用量和会话 ID 写进该任务行的最后一列
- 新增任务行必须 7 列，token 消耗列写用量（`input X / output Y ...`），或写「未知（原因）」
- 「未知」不带原因不算记录

**守卫**：`G-0020`，提交时检查 `docs/task-log.md` 中新增的任务行。
