---
id: EXP-20261018-0017
title: Agent 用 Get-ChildItem -Recurse 扫整个项目会刷爆上下文，必须先排除大目录
tags: [agent, token, shell, powershell]
severity: medium
status: active
seen: 1
source: 本次发现（审查英创项目文件时）
created: 2026-10-18
---

# Agent 用 Get-ChildItem -Recurse 扫整个项目会刷爆上下文，必须先排除大目录

**症状**：一条目录列表命令输出了 6000 多行，几乎全是 `node_modules` 和音频文件，输出被截断，还浪费大量 token。

**根因**：没有排除 `node_modules`、`dist`、音频等目录，也没有先过滤扩展名。

**规则**：
- 目录扫描一律排除 `node_modules`、`dist`、`.git`、音频（`*.wav`、`*.mp3`）、`package-lock.json`
- 先过滤再输出，只输出需要的列
- 找 md、skill 之类的文件，先按扩展名和路径过滤

示例：
```powershell
Get-ChildItem -Recurse -File | Where-Object { $_.FullName -notmatch '\\(node_modules|dist|\.git)\\' -and $_.Extension -in '.md','.json' }
```

**守卫**：`manual`：可以在 `AGENTS.base.md` 的 Token 节省一节里保持这条规则。
