---
id: EXP-20261018-0004
title: 新版本就绪后只在空闲时应用，不能立刻 reload
tags: [pwa, service-worker, ux]
severity: medium
status: active
seen: 1
source: YingChuangXingQiu PWA-03
created: 2026-10-18
---

# 新版本就绪后只在空闲时应用，不能立刻 reload

**症状**：更新就绪后立刻 reload，语音被切断，正在填的表单被清空。

**根因**：检测到更新不等于现在就该应用。`skipWaiting` 加立即刷新会打断正在进行的交互。

**规则**：更新只在空闲状态（没有在读、说、写）时应用。

**守卫**：`manual`：改 SW 更新路径时，人工核对空闲条件。
