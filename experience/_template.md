---
id: EXP-YYYYMMDD-XXXX
title: 一句话描述这个坑
tags: [关键词1, 关键词2]
severity: high | medium | low
status: active
guard: none   # 改成守卫 id，如 G-0014
seen: 1
source: <项目名> <项目内的 ID，如 PWA-02；没有就写 本次发现>
created: YYYY-MM-DD
---

# 一句话描述这个坑

**症状**：你实际会看到的现象（例：离线没声音，控制台无报错）

**根因**：为什么会发生

**规则**：以后要怎么做

**守卫**：`G-xxxx`（在 guards/guards.cjs 里实现）；不能自动检查时写 `guard: none` 并删去这一行
